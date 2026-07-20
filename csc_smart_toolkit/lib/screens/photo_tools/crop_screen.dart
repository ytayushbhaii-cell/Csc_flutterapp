import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

class _Ratio {
  const _Ratio(this.label, this.w, this.h);
  final String label;
  final double w, h;
}

const _ratios = [
  _Ratio('Free', 0, 0),
  _Ratio('1:1', 1, 1),
  _Ratio('4:3', 4, 3),
  _Ratio('3:4', 3, 4),
  _Ratio('16:9', 16, 9),
  _Ratio('9:16', 9, 16),
  _Ratio('3:2', 3, 2),
  _Ratio('2:3', 2, 3),
];

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});
  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> with PhotoToolMixin {
  _Ratio _selectedRatio = _ratios[1]; // default 1:1

  @override
  String get toolIdBase => 'photo-crop';
  @override
  String get toolNameBase => 'Photo Crop';

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.4; progressStage = 'Cropping…'; });
    final args = {
      'bytes': originalBytes!,
      'ratioW': _selectedRatio.w,
      'ratioH': _selectedRatio.h,
    };
    final result = await compute(_cropIsolate, args);
    if (!mounted) return;
    setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _cropIsolate(Map<String, dynamic> args) {
    final image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;

    final rw = args['ratioW'] as double;
    final rh = args['ratioH'] as double;

    img.Image cropped;
    if (rw == 0 || rh == 0) {
      // Free crop = centre square
      final side = image.width < image.height ? image.width : image.height;
      final x = (image.width - side) ~/ 2;
      final y = (image.height - side) ~/ 2;
      cropped = img.copyCrop(image, x: x, y: y, width: side, height: side);
    } else {
      final targetRatio = rw / rh;
      final srcRatio = image.width / image.height;
      if (srcRatio > targetRatio) {
        final newW = (image.height * targetRatio).round();
        final x = (image.width - newW) ~/ 2;
        cropped = img.copyCrop(image, x: x, y: 0, width: newW, height: image.height);
      } else {
        final newH = (image.width / targetRatio).round();
        final y = (image.height - newH) ~/ 2;
        cropped = img.copyCrop(image, x: 0, y: y, width: image.width, height: newH);
      }
    }

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhotoToolScaffold(
      title: 'Photo Crop',
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
      processLabel: 'Crop',
      processIcon: Icons.crop_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aspect Ratio', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _ratios.map((r) => ChoiceChip(
                  label: Text(r.label),
                  selected: _selectedRatio.label == r.label,
                  onSelected: (_) => setState(() => _selectedRatio = r),
                )).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Image will be centre-cropped to the selected ratio.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(140)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
