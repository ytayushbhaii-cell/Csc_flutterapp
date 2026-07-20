import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'export_service.dart';

/// Result from a share operation.
class ShareResult {
  const ShareResult({required this.success, this.error});
  final bool success;
  final String? error;
}

/// Thin wrapper around [SharePlus] that handles common share patterns used
/// across ID Card and Print Layout screens.
///
/// All methods accept raw bytes and an optional [filename] stem (no extension),
/// save to a temp file via [ExportService], then invoke the system share sheet.
class ShareService {
  ShareService._();

  // ── PNG ────────────────────────────────────────────────────────────────────

  /// Share image bytes as PNG.
  static Future<ShareResult> sharePng(
    Uint8List bytes, {
    String filename = 'image',
    String subject  = 'Image',
  }) async {
    try {
      final result = await ExportService.exportPng(bytes, filename: filename);
      await _shareFile(result.file, subject);
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  // ── JPG ────────────────────────────────────────────────────────────────────

  /// Share image bytes as JPEG.
  static Future<ShareResult> shareJpg(
    Uint8List bytes, {
    String filename = 'image',
    String subject  = 'Image',
    int quality     = 90,
  }) async {
    try {
      final result =
          await ExportService.exportJpg(bytes, filename: filename, quality: quality);
      await _shareFile(result.file, subject);
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  /// Share a PDF from raw bytes.
  static Future<ShareResult> sharePdf(
    Uint8List pdfBytes, {
    String filename = 'document',
    String subject  = 'PDF',
  }) async {
    try {
      final result = await ExportService.exportPdf(pdfBytes, filename: filename);
      await _shareFile(result.file, subject);
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  // ── Multiple files ─────────────────────────────────────────────────────────

  /// Share multiple [File] objects in a single share sheet invocation.
  static Future<ShareResult> shareMultiple(
    List<File> files, {
    String subject = 'Files',
  }) async {
    try {
      if (files.isEmpty) {
        return const ShareResult(success: false, error: 'No files provided.');
      }
      final xFiles = files.map((f) => XFile(f.path)).toList();
      await SharePlus.instance.share(
        ShareParams(files: xFiles, subject: subject),
      );
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  /// Share a ZIP file built from a list of raw byte buffers.
  static Future<ShareResult> shareZip(
    List<Uint8List> bytesList, {
    required List<String> names,
    String filename = 'export',
    String subject  = 'Files',
  }) async {
    try {
      final result = await ExportService.exportZipFromBytes(
        bytesList,
        names: names,
        filename: filename,
      );
      await _shareFile(result.file, subject);
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  // ── Single file (already on disk) ─────────────────────────────────────────

  /// Share a single [File] already on disk.
  static Future<ShareResult> shareFile(File file, {String subject = 'File'}) async {
    try {
      await _shareFile(file, subject);
      return const ShareResult(success: true);
    } catch (e) {
      return ShareResult(success: false, error: e.toString());
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _shareFile(File file, String subject) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}
