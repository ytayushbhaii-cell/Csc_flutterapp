import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Handles PNG / JPG export from raw image bytes.
class ImageExportService {
  ImageExportService._();

  /// Re-encode [bytes] as PNG (lossless).
  static Future<Uint8List> toPng(Uint8List bytes) async {
    return compute(_encodePng, bytes);
  }

  /// Re-encode [bytes] as JPEG at [quality] (1–100).
  static Future<Uint8List> toJpg(Uint8List bytes, {int quality = 90}) async {
    return compute(_encodeJpg, _JpgArgs(bytes, quality));
  }

  // Isolate workers ─────────────────────────────────────────────────────────

  static Uint8List _encodePng(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    return Uint8List.fromList(img.encodePng(image));
  }

  static Uint8List _encodeJpg(_JpgArgs args) {
    final image = img.decodeImage(args.bytes);
    if (image == null) return args.bytes;
    return Uint8List.fromList(img.encodeJpg(image, quality: args.quality));
  }
}

class _JpgArgs {
  const _JpgArgs(this.bytes, this.quality);
  final Uint8List bytes;
  final int quality;
}
