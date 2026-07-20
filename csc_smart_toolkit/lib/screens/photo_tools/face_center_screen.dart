import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// Face Center — crops to the upper-centre of the image where a face
/// typically appears. Full ML face detection is planned for Part 5+.
class FaceCenterScreen extends StatefulWidget {
  const FaceCenterScreen({super.key});
  @override
  State<FaceCenterScreen> createState() => _FaceCenterScreenState();
}

class _FaceCenterScreenState extends State<FaceCenterScreen>
    with PhotoToolMixin {
  double _faceRatio = 0.6; // fraction of image height to crop

  @override
  String get toolIdBase => 'face-center';
  @override
  String get toolNameBase => 'Face Center';

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.4; progressStage = 'Centering face…'; });
    final args = {'bytes': originalBytes!, 'ratio': _faceRatio};
    final result = await compute(_processIsolate, args);
    if (!mounted) return;
    setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _processIsolate(Map<String, dynamic> args) {
    final image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;
    final ratio = args['ratio'] as double;

    // Upper-centre crop: focus on top portion where face typically is
    final cropH = (image.height * ratio).round().clamp(1, image.height);
    final side = image.width < cropH ? image.width : cropH;
    final x = (image.width - side) ~/ 2;
    final y = (image.height * 0.05).round(); // slight top offset

    final cropped = img.copyCrop(image,
        x: x, y: y.clamp(0, image.height - 1),
        width: side, height: side.clamp(1, image.height - y));
    final resized = img.copyResize(cropped, width: 600, height: 600,
        interpolation: img.Interpolation.cubic);

    return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PhotoToolScaffold(
      title: 'Face Center',
      toolId: toolIdBase,
      category: 'Photo Tools',
      originalBytes: originalBytes,
      resultBytes: resultBytes,
      isProcessing: isProcessing,
      progress: progress,
      progressStage: progressStage,
      onPickImage: pickImageBase,
      onProcess: _process,
      onReset: resetBase,
      onSave: saveBase,
      onShare: shareBase,
      processLabel: 'Center Face',
      processIcon: Icons.face_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'ML face detection coming in Part 5. Currently uses smart upper-centre crop.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Crop Area', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('${(_faceRatio * 100).round()}%', style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
              Slider(value: _faceRatio, min: 0.3, max: 0.9, divisions: 12,
                  onChanged: (v) => setState(() => _faceRatio = v)),
              Text('Adjust how much of the image to include',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(140))),
            ],
          ),
        ),
      ),
    );
  }
}
