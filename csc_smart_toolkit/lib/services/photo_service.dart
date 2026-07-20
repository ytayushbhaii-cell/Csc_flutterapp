import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Core photo service: pick images, save to disk, share.
class PhotoService {
  PhotoService._();

  static final _picker = ImagePicker();

  /// Pick a single image from gallery or camera.
  static Future<Uint8List?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 100);
    if (xFile == null) return null;
    return xFile.readAsBytes();
  }

  /// Pick multiple images from gallery.
  static Future<List<Uint8List>> pickMultipleImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 100);
    final results = <Uint8List>[];
    for (final f in files) {
      results.add(await f.readAsBytes());
    }
    return results;
  }

  /// Save [bytes] to the app's documents directory with [filename].
  /// Returns the saved file path.
  static Future<String> saveToDocuments(
    Uint8List bytes,
    String filename,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final toolDir = Directory('${dir.path}/CSC_Smart_Toolkit');
    if (!toolDir.existsSync()) toolDir.createSync(recursive: true);
    final file = File('${toolDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share a file at [path] via the system share sheet.
  static Future<void> shareFile(
    String path, {
    String subject = 'Shared from CSC Smart Toolkit',
  }) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
  }

  /// Share [bytes] directly (saves to temp first).
  static Future<void> shareBytes(
    Uint8List bytes,
    String filename, {
    String subject = 'Shared from CSC Smart Toolkit',
  }) async {
    final path = await saveToDocuments(bytes, filename);
    await shareFile(path, subject: subject);
  }

  /// Show a snackbar confirming save.
  static void showSavedSnackbar(BuildContext context, String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${path.split('/').last}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Generate a timestamped filename.
  static String timestampFilename(String prefix, String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$ts.$ext';
  }
}
