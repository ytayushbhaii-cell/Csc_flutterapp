import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum BgFill { transparent, white, blue, red }

class _BgRemoveArgs {
  const _BgRemoveArgs(this.bytes, this.threshold, this.fill);
  final Uint8List bytes;
  final int threshold;
  final BgFill fill;
}

/// Offline background removal using corner-sample flood-fill.
/// No ML model required — works 100% on-device.
class BackgroundRemoveService {
  BackgroundRemoveService._();

  static Future<Uint8List> removeBackground(
    Uint8List bytes, {
    int threshold = 40,
    BgFill fill = BgFill.transparent,
  }) async {
    return compute(_process, _BgRemoveArgs(bytes, threshold, fill));
  }

  // ── Isolate worker ────────────────────────────────────────────────────────

  static Uint8List _process(_BgRemoveArgs args) {
    final src = img.decodeImage(args.bytes);
    if (src == null) return args.bytes;

    // Ensure RGBA
    final rgba = img.Image(
      width: src.width,
      height: src.height,
      numChannels: 4,
    );

    // Copy pixels
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        rgba.setPixelRgba(
            x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }

    // Sample background color from all four corners
    final corners = <img.Pixel>[
      src.getPixel(0, 0),
      src.getPixel(src.width - 1, 0),
      src.getPixel(0, src.height - 1),
      src.getPixel(src.width - 1, src.height - 1),
    ];

    int bgR = 0, bgG = 0, bgB = 0;
    for (final c in corners) {
      bgR += c.r.toInt();
      bgG += c.g.toInt();
      bgB += c.b.toInt();
    }
    bgR ~/= 4;
    bgG ~/= 4;
    bgB ~/= 4;

    final int thr = args.threshold * 3;

    // Determine fill RGBA
    final int fillR, fillG, fillB, fillA;
    switch (args.fill) {
      case BgFill.transparent:
        fillR = 0; fillG = 0; fillB = 0; fillA = 0;
      case BgFill.white:
        fillR = 255; fillG = 255; fillB = 255; fillA = 255;
      case BgFill.blue:
        fillR = 29; fillG = 78; fillB = 216; fillA = 255;
      case BgFill.red:
        fillR = 220; fillG = 38; fillB = 38; fillA = 255;
    }

    // Replace background pixels
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final dr = (p.r.toInt() - bgR).abs();
        final dg = (p.g.toInt() - bgG).abs();
        final db = (p.b.toInt() - bgB).abs();
        if (dr + dg + db < thr) {
          rgba.setPixelRgba(x, y, fillR, fillG, fillB, fillA);
        }
      }
    }

    // Feather edges: simple pass to soften jagged pixels
    for (int y = 1; y < rgba.height - 1; y++) {
      for (int x = 1; x < rgba.width - 1; x++) {
        final cur = rgba.getPixel(x, y);
        if (cur.a.toInt() == 0) {
          // Check if any neighbour is opaque
          final neighbours = [
            rgba.getPixel(x - 1, y),
            rgba.getPixel(x + 1, y),
            rgba.getPixel(x, y - 1),
            rgba.getPixel(x, y + 1),
          ];
          final opaqueCount =
              neighbours.where((p) => p.a.toInt() > 128).length;
          if (opaqueCount >= 2) {
            // Semi-transparent border pixel
            rgba.setPixelRgba(x, y, fillR, fillG, fillB, 128);
          }
        }
      }
    }

    return args.fill == BgFill.transparent
        ? Uint8List.fromList(img.encodePng(rgba))
        : Uint8List.fromList(img.encodeJpg(rgba, quality: 95));
  }
}
