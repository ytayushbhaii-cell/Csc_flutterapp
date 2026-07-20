import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Destination folder for saved files.
enum DownloadDestination {
  downloads,
  pictures,
  documents,
  custom,
}

/// Result returned after a save operation.
class DownloadResult {
  const DownloadResult({
    required this.success,
    required this.savedPath,
    this.error,
  });
  final bool success;
  final String savedPath;
  final String? error;
}

/// Service for saving files to persistent device storage.
///
/// On Android the app-specific external storage directory is used as the
/// parent; a named subfolder (Downloads / Pictures / Documents) is created
/// inside it so the files survive app reinstalls and are easy to find.
/// A custom path can be supplied via [DownloadDestination.custom].
class DownloadService {
  DownloadService._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Save [sourceFile] to the [destination] folder.
  ///
  /// [customPath] is required when [destination] is [DownloadDestination.custom].
  static Future<DownloadResult> saveFile(
    File sourceFile, {
    DownloadDestination destination = DownloadDestination.downloads,
    String? customPath,
    String? overrideName,
  }) async {
    try {
      final destDir = await _resolveDirectory(destination, customPath);
      if (destDir == null) {
        return const DownloadResult(
          success: false,
          savedPath: '',
          error: 'Could not resolve target directory.',
        );
      }

      await destDir.create(recursive: true);
      final fileName = overrideName ?? sourceFile.path.split('/').last;
      final target   = File('${destDir.path}/$fileName');
      await sourceFile.copy(target.path);
      return DownloadResult(success: true, savedPath: target.path);
    } catch (e) {
      return DownloadResult(success: false, savedPath: '', error: e.toString());
    }
  }

  /// Save [sourceFile] to the Downloads folder.
  static Future<DownloadResult> saveToDownloads(File file, {String? name}) =>
      saveFile(file, destination: DownloadDestination.downloads, overrideName: name);

  /// Save [sourceFile] to the Pictures folder.
  static Future<DownloadResult> saveToPictures(File file, {String? name}) =>
      saveFile(file, destination: DownloadDestination.pictures, overrideName: name);

  /// Save [sourceFile] to the Documents folder.
  static Future<DownloadResult> saveToDocuments(File file, {String? name}) =>
      saveFile(file, destination: DownloadDestination.documents, overrideName: name);

  /// Save [sourceFile] to a [customPath] directory.
  static Future<DownloadResult> saveToCustomFolder(
    File file,
    String folderPath, {
    String? name,
  }) =>
      saveFile(
        file,
        destination: DownloadDestination.custom,
        customPath: folderPath,
        overrideName: name,
      );

  // ── Permission helpers ─────────────────────────────────────────────────────

  /// Request storage permission on Android (no-op on other platforms).
  ///
  /// Returns `true` if permission is granted or not required.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses granular media permissions.
    final sdkInt = await _androidSdkVersion();
    if (sdkInt >= 33) return true; // writing to app-specific dir needs no perm

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static Future<Directory?> _resolveDirectory(
    DownloadDestination dest,
    String? customPath,
  ) async {
    switch (dest) {
      case DownloadDestination.custom:
        if (customPath == null) return null;
        return Directory(customPath);

      case DownloadDestination.downloads:
        return _publicSubdir('Download');

      case DownloadDestination.pictures:
        return _publicSubdir('Pictures/CSC Smart Toolkit');

      case DownloadDestination.documents:
        // getApplicationDocumentsDirectory is always accessible without perms.
        final appDocs = await getApplicationDocumentsDirectory();
        return Directory('${appDocs.path}/CSC Smart Toolkit');
    }
  }

  /// Try to construct a path inside the public external storage root.
  ///
  /// Falls back to the app-specific external directory when the public root
  /// cannot be determined.
  static Future<Directory> _publicSubdir(String subfolder) async {
    if (Platform.isAndroid) {
      // getExternalStorageDirectory → /sdcard/Android/data/<pkg>/files/
      // Its grandparent on a standard device is /sdcard/
      final appExternal = await getExternalStorageDirectory();
      if (appExternal != null) {
        // Walk up to /sdcard/
        final sdcard = appExternal.parent.parent.parent.parent;
        final pub = Directory('${sdcard.path}/$subfolder');
        // Verify the path looks sane before using it.
        if (sdcard.path.length > 1) return pub;
      }
    }

    // Safe fallback: app documents directory.
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/$subfolder');
  }

  static Future<int> _androidSdkVersion() async {
    try {
      if (!Platform.isAndroid) return 0;
      // Read the system property via dart:io
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
