import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFService {
  PDFService._();

  // ── Image list → PDF ──────────────────────────────────────────────────

  static Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document();
    for (final bytes in images) {
      final pdfImg = pw.MemoryImage(bytes);
      doc.addPage(pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (ctx) =>
            pw.Center(child: pw.Image(pdfImg, fit: pw.BoxFit.contain)),
      ));
    }
    return doc.save();
  }

  // ── PDF → Images ─────────────────────────────────────────────────────

  /// Render each page of [pdfBytes] to a PNG image at [dpi].
  static Future<List<Uint8List>> pdfToImages(
    Uint8List pdfBytes, {
    double dpi = 150,
  }) async {
    final result = <Uint8List>[];
    await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
      result.add(await page.toPng());
    }
    return result;
  }

  // ── Page count ───────────────────────────────────────────────────────

  static Future<int> getPageCount(Uint8List pdfBytes) async {
    var count = 0;
    // Use very low DPI for fast counting
    await for (final _ in Printing.raster(pdfBytes, dpi: 24)) {
      count++;
    }
    return count;
  }

  // ── Merge ────────────────────────────────────────────────────────────

  static Future<Uint8List> mergePdfs(List<Uint8List> pdfs) async {
    final allImages = <Uint8List>[];
    for (final pdf in pdfs) {
      allImages.addAll(await pdfToImages(pdf, dpi: 150));
    }
    return imagesToPdf(allImages);
  }

  // ── Split ────────────────────────────────────────────────────────────

  /// Split after page [splitAfterPage] (1-indexed). Returns 2 PDFs.
  static Future<List<Uint8List>> splitPdf(
      Uint8List pdfBytes, int splitAfterPage) async {
    final pages = await pdfToImages(pdfBytes, dpi: 150);
    if (splitAfterPage <= 0 || splitAfterPage >= pages.length) {
      return [pdfBytes];
    }
    return [
      await imagesToPdf(pages.sublist(0, splitAfterPage)),
      await imagesToPdf(pages.sublist(splitAfterPage)),
    ];
  }

  // ── Compress ─────────────────────────────────────────────────────────

  /// Re-render PDF at lower DPI. [quality] 0–100 maps to DPI 60–150.
  static Future<Uint8List> compressPdf(
    Uint8List pdfBytes, {
    int quality = 60,
  }) async {
    final dpi = 60.0 + (quality / 100.0) * 90.0;
    final pages = await pdfToImages(pdfBytes, dpi: dpi);
    return imagesToPdf(pages);
  }

  // ── Rotate ───────────────────────────────────────────────────────────

  static Future<Uint8List> rotatePdf(
      Uint8List pdfBytes, int degrees) async {
    final pages = await pdfToImages(pdfBytes, dpi: 150);
    final rotated = await Future.wait(
        pages.map((p) => compute(_rotateIsolate, {'b': p, 'd': degrees})));
    return imagesToPdf(rotated);
  }

  static Uint8List _rotateIsolate(Map<String, dynamic> args) {
    final src = img.decodeImage(args['b'] as Uint8List);
    if (src == null) return args['b'] as Uint8List;
    final r = img.copyRotate(src, angle: (args['d'] as int).toDouble());
    return Uint8List.fromList(img.encodePng(r));
  }

  // ── Extract pages ─────────────────────────────────────────────────────

  /// Keep only [pageNumbers] (1-indexed) in the result PDF.
  static Future<Uint8List> extractPages(
      Uint8List pdfBytes, List<int> pageNumbers) async {
    final all = await pdfToImages(pdfBytes, dpi: 150);
    final selected = pageNumbers
        .where((n) => n >= 1 && n <= all.length)
        .map((n) => all[n - 1])
        .toList();
    if (selected.isEmpty) return pdfBytes;
    return imagesToPdf(selected);
  }

  // ── Delete pages ──────────────────────────────────────────────────────

  /// Remove [pageNumbers] (1-indexed) from the PDF.
  static Future<Uint8List> deletePages(
      Uint8List pdfBytes, List<int> pageNumbers) async {
    final all = await pdfToImages(pdfBytes, dpi: 150);
    final toDelete = pageNumbers.toSet();
    final remaining = <Uint8List>[];
    for (var i = 0; i < all.length; i++) {
      if (!toDelete.contains(i + 1)) {
        remaining.add(all[i]);
      }
    }
    if (remaining.isEmpty) return pdfBytes;
    return imagesToPdf(remaining);
  }
}
