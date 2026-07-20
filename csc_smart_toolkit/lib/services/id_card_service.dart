import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Standard CR80 ID card dimensions in mm
class IDCardDimensions {
  static const double widthMm  = 85.6;
  static const double heightMm = 53.98;
  // 300 DPI equivalent in logical pixels (approx)
  static const double widthPx  = 640.0;
  static const double heightPx = 404.0;
}

/// Captures a RepaintBoundary widget to PNG bytes.
Future<Uint8List> captureWidget(GlobalKey key, {double pixelRatio = 3.0}) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class IDCardService {
  IDCardService._();

  /// Wrap an ID card PNG into an A4 PDF (centered).
  static Future<Uint8List> pngToPdf(
    Uint8List pngBytes, {
    String title = 'ID Card',
  }) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    // CR80 card in points (1 mm = 2.8346 pt)
    const cardWPt = IDCardDimensions.widthMm  * 2.8346;
    const cardHPt = IDCardDimensions.heightMm * 2.8346;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Center(
          child: pw.Container(
            width: cardWPt,
            height: cardHPt,
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// Wrap an ID card PNG into a PDF sized exactly to the card.
  static Future<Uint8List> pngToCardPdf(Uint8List pngBytes) async {
    const cardWPt = IDCardDimensions.widthMm  * 2.8346;
    const cardHPt = IDCardDimensions.heightMm * 2.8346;
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(cardWPt, cardHPt),
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Image(img, fit: pw.BoxFit.fill),
      ),
    );
    return doc.save();
  }
}
