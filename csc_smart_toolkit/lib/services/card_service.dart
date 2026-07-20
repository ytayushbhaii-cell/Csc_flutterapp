import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ── Card type ──────────────────────────────────────────────────────────────

enum CardType { aadhaar, pan, voter, drivingLicense, passport }

extension CardTypeX on CardType {
  String get displayName {
    switch (this) {
      case CardType.aadhaar:
        return 'Aadhaar';
      case CardType.pan:
        return 'PAN Card';
      case CardType.voter:
        return 'Voter ID';
      case CardType.drivingLicense:
        return 'Driving License';
      case CardType.passport:
        return 'Passport';
    }
  }

  Color get color {
    switch (this) {
      case CardType.aadhaar:
        return const Color(0xFF1D4ED8);
      case CardType.pan:
        return const Color(0xFFD97706);
      case CardType.voter:
        return const Color(0xFF059669);
      case CardType.drivingLicense:
        return const Color(0xFF7C3AED);
      case CardType.passport:
        return const Color(0xFF0891B2);
    }
  }

  String get category {
    switch (this) {
      case CardType.aadhaar:
        return 'Aadhaar Tools';
      case CardType.pan:
        return 'PAN Tools';
      case CardType.voter:
        return 'Voter ID Tools';
      case CardType.drivingLicense:
        return 'Driving License Tools';
      case CardType.passport:
        return 'Passport Tools';
    }
  }
}

// ── Internal dimensions (150 DPI) ─────────────────────────────────────────

class _Dim {
  static const double _pxPerMm = 150 / 25.4; // 5.906 px/mm
  static const double cardWmm = 85.6;
  static const double cardHmm = 53.98;
  static int get cardW => (cardWmm * _pxPerMm).round(); // 506
  static int get cardH => (cardHmm * _pxPerMm).round(); // 319
  static int get a4W => (210 * _pxPerMm).round(); // 1240
  static int get a4H => (297 * _pxPerMm).round(); // 1754
}

// ── CardService ────────────────────────────────────────────────────────────

class CardService {
  CardService._();

  // ── Crop ──────────────────────────────────────────────────────────────

  /// Centre-crop image to standard card aspect ratio, then resize to card px.
  static Future<Uint8List> cropCard(Uint8List bytes) =>
      compute(_cropIsolate, bytes);

  static Uint8List _cropIsolate(Uint8List bytes) {
    final src = img.decodeImage(bytes);
    if (src == null) return bytes;
    const aspect = _Dim.cardWmm / _Dim.cardHmm;
    final srcAspect = src.width / src.height;
    int cx, cy, cw, ch;
    if (srcAspect > aspect) {
      ch = src.height;
      cw = (ch * aspect).round();
      cx = (src.width - cw) ~/ 2;
      cy = 0;
    } else {
      cw = src.width;
      ch = (cw / aspect).round();
      cx = 0;
      cy = (src.height - ch) ~/ 2;
    }
    final cropped =
        img.copyCrop(src, x: cx, y: cy, width: cw, height: ch);
    final sized = img.copyResize(cropped,
        width: _Dim.cardW,
        height: _Dim.cardH,
        interpolation: img.Interpolation.cubic);
    return Uint8List.fromList(img.encodeJpg(sized, quality: 95));
  }

  // ── Copies layout ─────────────────────────────────────────────────────

  /// Arrange [copies] card images on a white A4 canvas.
  static Future<Uint8List> createCopiesLayout(Uint8List bytes, int copies) =>
      compute(_copiesIsolate, {'b': bytes, 'n': copies});

  static Uint8List _copiesIsolate(Map<String, dynamic> args) {
    final src = img.decodeImage(args['b'] as Uint8List);
    if (src == null) return args['b'] as Uint8List;
    final copies = args['n'] as int;
    final card = img.copyResize(src,
        width: _Dim.cardW,
        height: _Dim.cardH,
        interpolation: img.Interpolation.cubic);
    final a4 = img.Image(width: _Dim.a4W, height: _Dim.a4H);
    img.fill(a4, color: img.ColorRgb8(255, 255, 255));

    const cols = 2;
    const gap = 22;
    final rows = (copies / cols).ceil();
    final totalW = cols * card.width + (cols - 1) * gap;
    final totalH = rows * card.height + (rows - 1) * gap;
    final startX = (a4.width - totalW) ~/ 2;
    final startY = (a4.height - totalH) ~/ 2;

    for (var i = 0; i < copies; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      img.compositeImage(a4, card,
          dstX: startX + col * (card.width + gap),
          dstY: startY + row * (card.height + gap));
    }
    return Uint8List.fromList(img.encodePng(a4));
  }

  // ── Front + Back layout ──────────────────────────────────────────────

  /// Place front card above back card, both centred, on an A4 canvas.
  static Future<Uint8List> createFrontBackLayout(
          Uint8List front, Uint8List back) =>
      compute(_frontBackIsolate, {'f': front, 'b': back});

  static Uint8List _frontBackIsolate(Map<String, dynamic> args) {
    final f = img.decodeImage(args['f'] as Uint8List);
    final b = img.decodeImage(args['b'] as Uint8List);
    if (f == null || b == null) return args['f'] as Uint8List;
    final frontR =
        img.copyResize(f, width: _Dim.cardW, height: _Dim.cardH);
    final backR =
        img.copyResize(b, width: _Dim.cardW, height: _Dim.cardH);
    final a4 = img.Image(width: _Dim.a4W, height: _Dim.a4H);
    img.fill(a4, color: img.ColorRgb8(255, 255, 255));
    final cx = (a4.width - _Dim.cardW) ~/ 2;
    const gap = 44;
    final totalH = _Dim.cardH * 2 + gap;
    final startY = (a4.height - totalH) ~/ 2;
    img.compositeImage(a4, frontR, dstX: cx, dstY: startY);
    img.compositeImage(a4, backR, dstX: cx, dstY: startY + _Dim.cardH + gap);
    return Uint8List.fromList(img.encodePng(a4));
  }

  // ── Color correction ─────────────────────────────────────────────────

  static Future<Uint8List> colorCorrect(Uint8List bytes) =>
      compute(_colorCorrectIsolate, bytes);

  static Uint8List _colorCorrectIsolate(Uint8List bytes) {
    final src = img.decodeImage(bytes);
    if (src == null) return bytes;
    var out = img.adjustColor(src,
        brightness: 0.05, contrast: 0.15, saturation: 0.10);
    out = img.convolution(out,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1, offset: 0);
    return Uint8List.fromList(img.encodeJpg(out, quality: 95));
  }

  // ── Image → PDF ───────────────────────────────────────────────────────

  /// Wrap [imageBytes] in a single-page A4 PDF.
  static Future<Uint8List> toPdf(Uint8List imageBytes) async {
    final doc = pw.Document();
    final pdfImg = pw.MemoryImage(imageBytes);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) =>
          pw.Center(child: pw.Image(pdfImg, fit: pw.BoxFit.contain)),
    ));
    return doc.save();
  }
}
