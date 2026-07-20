import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shape for stamps
enum StampShape { round, square }

extension StampShapeLabel on StampShape {
  String get label => this == StampShape.round ? 'Round' : 'Square';
}

/// Ink color presets
class InkColor {
  const InkColor(this.label, this.value);
  final String label;
  final int value; // ARGB hex

  static const List<InkColor> presets = [
    InkColor('Blue',   0xFF1A237E),
    InkColor('Red',    0xFFB71C1C),
    InkColor('Black',  0xFF212121),
    InkColor('Green',  0xFF1B5E20),
    InkColor('Purple', 0xFF4A148C),
  ];
}

class StampService {
  StampService._();

  /// Capture a stamp widget (RepaintBoundary) to PNG bytes.
  static Future<Uint8List> captureWidget(GlobalKey key,
      {double pixelRatio = 3.0}) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Wrap stamp PNG into a PDF.
  static Future<Uint8List> pngToPdf(Uint8List pngBytes,
      {String title = 'Stamp',
      double pageWidthPt = 350,
      double pageHeightPt = 350}) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
      ),
    );
    return doc.save();
  }
}
