---
name: image 4.x isolate pattern
description: How to correctly use the `image` 4.x package with Flutter's compute() for background processing
---

## Rule
All `image` package processing (decode, resize, crop, rotate, encode) must run inside `compute()` so the UI thread stays unblocked.

**Why:** `img.decodeImage` on large photos can take 500ms–2s on device, freezing the UI if run on the main thread.

**How to apply:**
```dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// Top-level or static method (required by compute):
static Uint8List _processIsolate(Map<String, dynamic> args) {
  final image = img.decodeImage(args['bytes'] as Uint8List);
  if (image == null) return args['bytes'] as Uint8List;
  final result = img.copyResize(image, width: args['w'] as int);
  return Uint8List.fromList(img.encodeJpg(result, quality: 95));
}

// Call site:
final result = await compute(_processIsolate, {'bytes': bytes, 'w': 800});
```

**Key APIs (image 4.x):**
- `img.decodeImage(Uint8List)` → `img.Image?`
- `img.copyResize(image, width:, height:, interpolation: img.Interpolation.cubic)`
- `img.copyCrop(image, x:, y:, width:, height:)`
- `img.copyRotate(image, angle: double)` — angle in degrees
- `img.flipHorizontal(image)` / `img.flipVertical(image)`
- `img.adjustColor(image, brightness:, contrast:, saturation:)` — values relative to 1.0
- `img.convolution(image, filter: List<num>, div:, offset:)` — for sharpen kernel
- `img.encodePng(image)` / `img.encodeJpg(image, quality: int)`
- `img.fill(image, color: img.ColorRgb8(r,g,b))`
- `img.compositeImage(dst, src, dstX:, dstY:)`
- Pixel access: `image.getPixel(x,y)` → `Pixel`; `.r.toInt()`, `.g.toInt()`, `.b.toInt()`, `.a.toInt()`
- `image.setPixelRgba(x, y, r, g, b, a)`

**Note:** `dart:typed_data` is already provided by `package:flutter/foundation.dart` — do not double-import.
