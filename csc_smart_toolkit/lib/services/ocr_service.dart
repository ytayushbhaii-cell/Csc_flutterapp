import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Offline OCR service backed by Google ML Kit (model bundled in APK).
class OCRService {
  OCRService._();

  /// Extract text from an image [bytes] (JPEG or PNG).
  static Future<String> extractFromImage(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(path);
    await file.writeAsBytes(bytes);

    final recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(file);
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer.close();
      if (await file.exists()) await file.delete();
    }
  }

  /// Extract and concatenate text from all [pageImages].
  static Future<String> extractFromPages(List<Uint8List> pageImages) async {
    final buf = StringBuffer();
    for (var i = 0; i < pageImages.length; i++) {
      if (i > 0) buf.writeln('\n── Page ${i + 1} ──\n');
      buf.writeln(await extractFromImage(pageImages[i]));
    }
    return buf.toString().trim();
  }
}
