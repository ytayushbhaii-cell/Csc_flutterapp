import 'dart:typed_data';

enum PhotoFormat { png, jpg }

/// Holds original + processed image bytes for any photo tool.
class PhotoResult {
  const PhotoResult({
    required this.originalBytes,
    this.processedBytes,
    this.format = PhotoFormat.png,
    this.savedPath,
  });

  final Uint8List originalBytes;
  final Uint8List? processedBytes;
  final PhotoFormat format;
  final String? savedPath;

  PhotoResult copyWith({
    Uint8List? processedBytes,
    PhotoFormat? format,
    String? savedPath,
  }) =>
      PhotoResult(
        originalBytes: originalBytes,
        processedBytes: processedBytes ?? this.processedBytes,
        format: format ?? this.format,
        savedPath: savedPath ?? this.savedPath,
      );

  bool get hasResult => processedBytes != null;
}

/// Progress stage during image processing.
class ProcessingStage {
  const ProcessingStage(this.label, this.progress);
  final String label;
  final double progress;
}

const List<ProcessingStage> bgRemoveStages = [
  ProcessingStage('Loading image…', 0.10),
  ProcessingStage('Analyzing background…', 0.30),
  ProcessingStage('Removing background…', 0.60),
  ProcessingStage('Refining edges…', 0.85),
  ProcessingStage('Preparing export…', 1.00),
];

const List<ProcessingStage> generalStages = [
  ProcessingStage('Loading image…', 0.20),
  ProcessingStage('Processing…', 0.60),
  ProcessingStage('Finalizing…', 0.90),
  ProcessingStage('Done', 1.00),
];
