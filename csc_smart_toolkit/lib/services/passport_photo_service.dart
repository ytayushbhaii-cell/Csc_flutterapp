import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Standard photo sizes at 300 DPI (pixels = mm * 300 / 25.4)
class PhotoSize {
  const PhotoSize({
    required this.label,
    required this.widthPx,
    required this.heightPx,
    required this.widthMm,
    required this.heightMm,
  });

  final String label;
  final int widthPx;
  final int heightPx;
  final double widthMm;
  final double heightMm;

  static const passport = PhotoSize(
    label: 'Passport (51×51 mm)',
    widthPx: 600, heightPx: 600,
    widthMm: 51, heightMm: 51,
  );
  static const visa = PhotoSize(
    label: 'Visa (35×45 mm)',
    widthPx: 413, heightPx: 531,
    widthMm: 35, heightMm: 45,
  );
  static const stamp = PhotoSize(
    label: 'Stamp (25×30 mm)',
    widthPx: 295, heightPx: 354,
    widthMm: 25, heightMm: 30,
  );

  static const all = [passport, visa, stamp];
}

class _PassportArgs {
  const _PassportArgs(this.bytes, this.size, this.copies);
  final Uint8List bytes;
  final PhotoSize size;
  final int copies;
}

class PassportPhotoService {
  PassportPhotoService._();

  /// Crop-centre + resize to [size], return JPG bytes.
  static Future<Uint8List> makePhoto(
    Uint8List bytes,
    PhotoSize size, {
    int copies = 1,
  }) async {
    return compute(_process, _PassportArgs(bytes, size, copies));
  }

  static Uint8List _process(_PassportArgs args) {
    final src = img.decodeImage(args.bytes);
    if (src == null) return args.bytes;

    // Centre-crop to square first if portrait/landscape mismatch
    final targetRatio = args.size.widthPx / args.size.heightPx;
    final srcRatio = src.width / src.height;

    img.Image cropped;
    if ((srcRatio - targetRatio).abs() < 0.01) {
      cropped = src;
    } else if (srcRatio > targetRatio) {
      // Source wider — crop sides
      final newW = (src.height * targetRatio).round();
      final x = (src.width - newW) ~/ 2;
      cropped = img.copyCrop(src, x: x, y: 0, width: newW, height: src.height);
    } else {
      // Source taller — crop top/bottom
      final newH = (src.width / targetRatio).round();
      final y = (src.height - newH) ~/ 2;
      cropped = img.copyCrop(src, x: 0, y: y, width: src.width, height: newH);
    }

    final resized = img.copyResize(
      cropped,
      width: args.size.widthPx,
      height: args.size.heightPx,
      interpolation: img.Interpolation.cubic,
    );

    if (args.copies <= 1) {
      return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
    }

    // Arrange multiple copies on a white A4 canvas (2480×3508 px @ 300dpi)
    const a4W = 2480, a4H = 3508, margin = 60, gap = 20;
    final sheet = img.Image(width: a4W, height: a4H, numChannels: 3);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));

    int row = 0;
    int x = margin, y = margin;

    for (int i = 0; i < args.copies; i++) {
      if (x + args.size.widthPx > a4W - margin) {
        row++;
        x = margin;
        y = margin + row * (args.size.heightPx + gap);
      }
      if (y + args.size.heightPx > a4H - margin) break;
      img.compositeImage(sheet, resized, dstX: x, dstY: y);
      x += args.size.widthPx + gap;
    }

    return Uint8List.fromList(img.encodeJpg(sheet, quality: 95));
  }
}
