import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Standard paper sizes in mm (width × height for portrait).
class PaperSize {
  const PaperSize(this.name, this.widthMm, this.heightMm);
  final String name;
  final double widthMm;
  final double heightMm;

  PdfPageFormat get pdfFormat =>
      PdfPageFormat(widthMm * mmToPt, heightMm * mmToPt);

  static const double mmToPt = 2.8346;

  static const PaperSize a4     = PaperSize('A4',     210.0, 297.0);
  static const PaperSize legal  = PaperSize('Legal',  216.0, 356.0);
  static const PaperSize letter = PaperSize('Letter', 216.0, 279.0);
  static const PaperSize photo4x6 = PaperSize('Photo 4×6', 101.6, 152.4);
  static const PaperSize photo5x7 = PaperSize('Photo 5×7', 127.0, 177.8);

  static const List<PaperSize> all = [a4, legal, letter, photo4x6, photo5x7];
}

/// Grid cell layout for multiple copies
class GridLayout {
  const GridLayout({
    required this.cols,
    required this.rows,
    required this.cellWidthMm,
    required this.cellHeightMm,
    required this.hGapMm,
    required this.vGapMm,
    required this.marginMm,
  });
  final int cols;
  final int rows;
  final double cellWidthMm;
  final double cellHeightMm;
  final double hGapMm;
  final double vGapMm;
  final double marginMm;

  int get capacity => cols * rows;
}

class PrintLayoutService {
  PrintLayoutService._();

  /// Calculate optimal grid layout for [copies] items on [paper] with [itemW]×[itemH] mm items.
  static GridLayout calculateGrid({
    required PaperSize paper,
    required double itemWidthMm,
    required double itemHeightMm,
    required int copies,
    double marginMm = 10.0,
    double gapMm = 5.0,
  }) {
    final usableW = paper.widthMm  - marginMm * 2;
    final usableH = paper.heightMm - marginMm * 2;

    int bestCols = 1, bestRows = 1;
    double bestArea = 0;

    for (int c = 1; c <= 10; c++) {
      for (int r = 1; r <= 20; r++) {
        if (c * r < copies) continue;
        final cw = (usableW - gapMm * (c - 1)) / c;
        final ch = (usableH - gapMm * (r - 1)) / r;
        if (cw <= 0 || ch <= 0) continue;
        // Scale to fit item aspect ratio
        final scale = (cw / itemWidthMm).clamp(0.0, ch / itemHeightMm);
        final area  = scale * scale;
        if (area > bestArea) {
          bestArea = area;
          bestCols = c;
          bestRows = r;
        }
      }
    }

    final cw = (usableW - gapMm * (bestCols - 1)) / bestCols;
    final ch = (usableH - gapMm * (bestRows - 1)) / bestRows;

    return GridLayout(
      cols: bestCols,
      rows: bestRows,
      cellWidthMm: cw,
      cellHeightMm: ch,
      hGapMm: gapMm,
      vGapMm: gapMm,
      marginMm: marginMm,
    );
  }

  /// Build a PDF with [copies] copies of [imageBytes] on a [paper] sheet.
  static Future<Uint8List> buildMultiCopyPdf({
    required Uint8List imageBytes,
    required PaperSize paper,
    required int copies,
    double marginMm = 10.0,
    double gapMm = 5.0,
    bool autoCenter = true,
  }) async {
    const imgW = 85.6; // default to CR80 card width mm
    const imgH = 53.98;

    final layout = calculateGrid(
      paper: paper,
      itemWidthMm: imgW,
      itemHeightMm: imgH,
      copies: copies,
      marginMm: marginMm,
      gapMm: gapMm,
    );

    final doc  = pw.Document();
    final img  = pw.MemoryImage(imageBytes);
    const mPt  = PaperSize.mmToPt;

    final cellW = layout.cellWidthMm  * mPt;
    final cellH = layout.cellHeightMm * mPt;
    final hGap  = layout.hGapMm  * mPt;
    final vGap  = layout.vGapMm  * mPt;
    final margin = layout.marginMm * mPt;

    doc.addPage(
      pw.Page(
        pageFormat: paper.pdfFormat,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          final items = <pw.Widget>[];
          int placed = 0;
          for (int r = 0; r < layout.rows && placed < copies; r++) {
            for (int c = 0; c < layout.cols && placed < copies; c++) {
              items.add(
                pw.Positioned(
                  left: margin + c * (cellW + hGap),
                  top:  margin + r * (cellH + vGap),
                  child: pw.SizedBox(
                    width: cellW, height: cellH,
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ),
                ),
              );
              placed++;
            }
          }
          return pw.Stack(children: items);
        },
      ),
    );
    return doc.save();
  }

  /// Build a single-image PDF on [paper] with margins and optional centering.
  static Future<Uint8List> buildSingleImagePdf({
    required Uint8List imageBytes,
    required PaperSize paper,
    double marginMm = 10.0,
    bool autoCenter = true,
    bool fitToPage = false,
  }) async {
    final doc    = pw.Document();
    final img    = pw.MemoryImage(imageBytes);
    const mPt    = PaperSize.mmToPt;
    final margin = marginMm * mPt;

    doc.addPage(
      pw.Page(
        pageFormat: paper.pdfFormat,
        margin: pw.EdgeInsets.all(margin),
        build: (ctx) {
          if (fitToPage) {
            return pw.Image(img, fit: pw.BoxFit.contain);
          }
          if (autoCenter) {
            return pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain));
          }
          return pw.Image(img, fit: pw.BoxFit.contain);
        },
      ),
    );
    return doc.save();
  }

  /// Passport photo sheet: places each photo at the **exact physical size**
  /// [itemWidthMm] × [itemHeightMm] on an A4 sheet.
  ///
  /// Rows and columns are derived from how many fixed-size items fit within the
  /// usable area (page minus [marginMm] on each side, [gapMm] between items).
  /// [copies] is clamped to the true page capacity so the PDF is always correct.
  static Future<Uint8List> buildPassportSheet({
    required Uint8List photoBytes,
    required int copies,
    required double itemWidthMm,
    required double itemHeightMm,
    double gapMm = 3.0,
    double marginMm = 8.0,
  }) async {
    const paper  = PaperSize.a4;
    const mPt    = PaperSize.mmToPt;

    // Fixed physical dimensions in PDF points
    final itemWPt = itemWidthMm  * mPt;
    final itemHPt = itemHeightMm * mPt;
    final gapPt   = gapMm   * mPt;
    final margPt  = marginMm * mPt;

    final pageWPt = paper.widthMm  * mPt;
    final pageHPt = paper.heightMm * mPt;
    final usableW = pageWPt - margPt * 2;
    final usableH = pageHPt - margPt * 2;

    // How many items fit per row / column at fixed size
    final cols = ((usableW + gapPt) / (itemWPt + gapPt)).floor().clamp(1, 99);
    final rows = ((usableH + gapPt) / (itemHPt + gapPt)).floor().clamp(1, 99);
    final capacity = cols * rows;
    final count = copies.clamp(1, capacity);

    final doc = pw.Document();
    final img = pw.MemoryImage(photoBytes);

    doc.addPage(pw.Page(
      pageFormat: paper.pdfFormat,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        final items = <pw.Widget>[];
        int placed = 0;
        for (int r = 0; r < rows && placed < count; r++) {
          for (int c = 0; c < cols && placed < count; c++) {
            items.add(pw.Positioned(
              left: margPt + c * (itemWPt + gapPt),
              top:  margPt + r * (itemHPt + gapPt),
              child: pw.SizedBox(
                width: itemWPt, height: itemHPt,
                // BoxFit.fill renders the photo at exactly the target mm size
                child: pw.Image(img, fit: pw.BoxFit.fill),
              ),
            ));
            placed++;
          }
        }
        return pw.Stack(children: items);
      },
    ));
    return doc.save();
  }
}

/// Captures a RepaintBoundary to PNG bytes.
Future<Uint8List> captureRepaint(GlobalKey key, {double pixelRatio = 2.0}) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final data  = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
