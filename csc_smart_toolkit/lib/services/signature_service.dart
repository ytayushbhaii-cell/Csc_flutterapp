import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SignatureService {
  SignatureService._();

  /// Capture a RepaintBoundary as PNG bytes.
  static Future<Uint8List> captureWidget(GlobalKey key,
      {double pixelRatio = 3.0}) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Convert ui.Image from signature controller to PNG bytes.
  static Future<Uint8List> uiImageToPng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Wrap PNG signature into a PDF page.
  static Future<Uint8List> pngToPdf(Uint8List pngBytes,
      {String title = 'Signature',
      double pageWidthPt = 400,
      double pageHeightPt = 250}) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
            pw.Expanded(
              child: pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
