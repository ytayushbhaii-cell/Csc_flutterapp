import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../services/photo_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});
  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> with PhotoToolMixin {
  int _quality = 80;
  int _originalSize = 0;
  int _resultSize = 0;

  @override
  String get toolIdBase => 'photo-compress';
  @override
  String get toolNameBase => 'Photo Compress';

  @override
  Future<void> pickImageBase() async {
    final bytes = await PhotoService.pickImage();
    if (bytes == null) return;
    setState(() {
      originalBytes = bytes;
      resultBytes = null;
      _originalSize = bytes.length;
      _resultSize = 0;
    });
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.4; progressStage = 'Compressing…'; });
    final result = await compute(_compressIsolate, {'bytes': originalBytes!, 'quality': _quality});
    if (!mounted) return;
    setState(() {
      resultBytes = result;
      _resultSize = result.length;
      isProcessing = false;
      progress = 1.0;
      progressStage = 'Done';
    });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _compressIsolate(Map<String, dynamic> args) {
    final image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;
    return Uint8List.fromList(img.encodeJpg(image, quality: args['quality'] as int));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final saved = _originalSize > 0 && _resultSize > 0
        ? ((1 - _resultSize / _originalSize) * 100).clamp(0, 100).round()
        : 0;

    return PhotoToolScaffold(
      title: 'Photo Compress',
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
      processLabel: 'Compress',
      processIcon: Icons.compress,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Quality', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('$_quality%', style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
              Slider(value: _quality.toDouble(), min: 10, max: 100, divisions: 18,
                  label: '$_quality%',
                  onChanged: (v) => setState(() { _quality = v.round(); resultBytes = null; })),
              Text(_quality >= 80 ? 'High quality, larger file' : _quality >= 50
                  ? 'Balanced quality and size' : 'Smaller file, lower quality',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(150))),
              if (_resultSize > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SizeChip(label: 'Original', value: _formatSize(_originalSize), color: cs.error)),
                  const SizedBox(width: 8),
                  Expanded(child: _SizeChip(label: 'Result', value: _formatSize(_resultSize), color: Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _SizeChip(label: 'Saved', value: '$saved%', color: cs.primary)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
