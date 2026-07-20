import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Supported export formats.
enum ExportFormat { png, jpg, pdf, zip }

/// Result returned by every export operation.
class ExportResult {
  const ExportResult({required this.file, required this.format});
  final File file;
  final ExportFormat format;

  String get mimeType {
    switch (format) {
      case ExportFormat.png: return 'image/png';
      case ExportFormat.jpg: return 'image/jpeg';
      case ExportFormat.pdf: return 'application/pdf';
      case ExportFormat.zip: return 'application/zip';
    }
  }
}

/// Central service for exporting image/PDF/ZIP data to temp storage.
///
/// All methods write to [getTemporaryDirectory] and return an [ExportResult]
/// that callers can then hand to [ShareService] or [DownloadService].
class ExportService {
  ExportService._();

  // ── PNG ────────────────────────────────────────────────────────────────────

  /// Save [pngBytes] as a PNG file. If the bytes are already PNG-encoded they
  /// are written as-is; otherwise they are re-encoded via the `image` package.
  static Future<ExportResult> exportPng(
    Uint8List bytes, {
    String filename = 'export',
  }) async {
    final outBytes = await compute(_reEncodePng, bytes);
    final file = await _tmpFile('${filename}_${_ts()}.png');
    await file.writeAsBytes(outBytes);
    return ExportResult(file: file, format: ExportFormat.png);
  }

  // ── JPG ────────────────────────────────────────────────────────────────────

  /// Re-encode [bytes] as JPEG at [quality] (1–100) and write to disk.
  static Future<ExportResult> exportJpg(
    Uint8List bytes, {
    String filename = 'export',
    int quality = 90,
  }) async {
    final outBytes = await compute(_reEncodeJpg, _JpgArgs(bytes, quality));
    final file = await _tmpFile('${filename}_${_ts()}.jpg');
    await file.writeAsBytes(outBytes);
    return ExportResult(file: file, format: ExportFormat.jpg);
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  /// Write raw PDF [bytes] to disk (already-generated PDF pass-through).
  static Future<ExportResult> exportPdf(
    Uint8List bytes, {
    String filename = 'export',
  }) async {
    final file = await _tmpFile('${filename}_${_ts()}.pdf');
    await file.writeAsBytes(bytes);
    return ExportResult(file: file, format: ExportFormat.pdf);
  }

  /// Build a single-page PDF that wraps [imageBytes] (any format decodable by
  /// the `image` package) and write it to disk.
  static Future<ExportResult> imageToPdf(
    Uint8List imageBytes, {
    String filename = 'export',
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool autoCenter = true,
    bool fitToPage = false,
    double marginMm = 10.0,
  }) async {
    const mPt = 2.8346;
    final doc    = pw.Document();
    final img_   = pw.MemoryImage(imageBytes);
    final margin = marginMm * mPt;

    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.all(margin),
      build: (ctx) {
        if (fitToPage) return pw.Image(img_, fit: pw.BoxFit.contain);
        if (autoCenter) {
          return pw.Center(child: pw.Image(img_, fit: pw.BoxFit.contain));
        }
        return pw.Image(img_, fit: pw.BoxFit.contain);
      },
    ));

    final pdfBytes = await doc.save();
    final file = await _tmpFile('${filename}_${_ts()}.pdf');
    await file.writeAsBytes(pdfBytes);
    return ExportResult(file: file, format: ExportFormat.pdf);
  }

  // ── ZIP ────────────────────────────────────────────────────────────────────

  /// Package a list of [files] into a single ZIP archive.
  ///
  /// [names] must be the same length as [files] and gives each entry its
  /// filename inside the ZIP.  If [names] is shorter, remaining files are
  /// given auto-generated names.
  static Future<ExportResult> exportZip(
    List<File> files, {
    List<String>? names,
    String filename = 'export',
  }) async {
    final archive = Archive();
    for (int i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final name  = (names != null && i < names.length)
          ? names[i]
          : 'file_${i + 1}${_extOf(files[i])}';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive) ?? []);
    final file = await _tmpFile('${filename}_${_ts()}.zip');
    await file.writeAsBytes(zipBytes);
    return ExportResult(file: file, format: ExportFormat.zip);
  }

  /// Convenience: package multiple raw byte buffers into a ZIP without first
  /// writing them to disk individually.
  static Future<ExportResult> exportZipFromBytes(
    List<Uint8List> bytesList, {
    required List<String> names,
    String filename = 'export',
  }) async {
    final archive = Archive();
    for (int i = 0; i < bytesList.length; i++) {
      final name = i < names.length ? names[i] : 'file_${i + 1}.bin';
      archive.addFile(ArchiveFile(name, bytesList[i].length, bytesList[i]));
    }
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive) ?? []);
    final file = await _tmpFile('${filename}_${_ts()}.zip');
    await file.writeAsBytes(zipBytes);
    return ExportResult(file: file, format: ExportFormat.zip);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Future<File> _tmpFile(String name) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$name');
  }

  static String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  static String _extOf(File f) {
    final n = f.path.split('/').last;
    final dot = n.lastIndexOf('.');
    return dot >= 0 ? n.substring(dot) : '';
  }

  // ── Isolate workers ────────────────────────────────────────────────────────

  static Uint8List _reEncodePng(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    return Uint8List.fromList(img.encodePng(decoded));
  }

  static Uint8List _reEncodeJpg(_JpgArgs args) {
    final decoded = img.decodeImage(args.bytes);
    if (decoded == null) return args.bytes;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: args.quality));
  }
}

class _JpgArgs {
  const _JpgArgs(this.bytes, this.quality);
  final Uint8List bytes;
  final int quality;
}
