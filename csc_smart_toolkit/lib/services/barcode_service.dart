import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'qr_service.dart';

/// Supported 1-D barcode formats
enum BarcodeFormat { code128, ean13, upc, code39 }

extension BarcodeFormatLabel on BarcodeFormat {
  String get label {
    switch (this) {
      case BarcodeFormat.code128: return 'Code 128';
      case BarcodeFormat.ean13:   return 'EAN-13';
      case BarcodeFormat.upc:     return 'UPC-A';
      case BarcodeFormat.code39:  return 'Code 39';
    }
  }

  String get hint {
    switch (this) {
      case BarcodeFormat.code128: return 'Any text/numbers';
      case BarcodeFormat.ean13:   return '12 digits + check';
      case BarcodeFormat.upc:     return '11 digits + check';
      case BarcodeFormat.code39:  return r'A-Z, 0-9, -+$%/ .';
    }
  }

  /// The barcode_widget Barcode type
  Barcode get barcodeType {
    switch (this) {
      case BarcodeFormat.code128: return Barcode.code128();
      case BarcodeFormat.ean13:   return Barcode.ean13();
      case BarcodeFormat.upc:     return Barcode.upcA();
      case BarcodeFormat.code39:  return Barcode.code39();
    }
  }
}

class BarcodeService {
  BarcodeService._();

  /// Validate that [data] is acceptable for [format].
  /// Returns null if valid, otherwise an error message.
  static String? validate(String data, BarcodeFormat format) {
    if (data.isEmpty) return 'Enter barcode value';
    switch (format) {
      case BarcodeFormat.code128:
        return null; // accepts anything
      case BarcodeFormat.ean13:
        final digits = data.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 12 && digits.length != 13) {
          return 'EAN-13 requires 12 or 13 digits';
        }
        return null;
      case BarcodeFormat.upc:
        final digits = data.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 11 && digits.length != 12) {
          return 'UPC-A requires 11 or 12 digits';
        }
        return null;
      case BarcodeFormat.code39:
        final valid = RegExp(r'^[A-Z0-9\-\.\ \$\/\+\%]+$');
        if (!valid.hasMatch(data.toUpperCase())) {
          return 'Code 39 allows A–Z, 0–9, - . \$ / + % space';
        }
        return null;
    }
  }

  // ── Export helpers ─────────────────────────────────────────────────────────

  /// Wrap PNG bytes into a barcode PDF page.
  static Future<Uint8List> pngToPdf(Uint8List pngBytes,
      {String? label, double pageWidthPt = 400, double pageHeightPt = 200}) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Image(img, fit: pw.BoxFit.contain),
            if (label != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center),
            ],
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Capture widget using shared QRService helper.
  static Future<Uint8List> captureWidget(GlobalKey key,
          {double pixelRatio = 3.0}) =>
      QRService.captureWidget(key, pixelRatio: pixelRatio);
}
