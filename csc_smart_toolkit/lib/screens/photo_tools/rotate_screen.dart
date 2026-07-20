import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// Rotate & Mirror screen.
/// [initialTab]: 0=Rotate, 1=Mirror
class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen>
    with PhotoToolMixin, SingleTickerProviderStateMixin {
  late TabController _tabs;
  double _angle = 90;
  bool _flipH = true; // mirror = horizontal flip by default

  @override
  String get toolIdBase => 'rotate';
  @override
  String get toolNameBase => 'Rotate & Mirror';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.4; progressStage = 'Processing…'; });
    final isRotate = _tabs.index == 0;
    final args = {'bytes': originalBytes!, 'angle': _angle, 'flipH': _flipH, 'isRotate': isRotate};
    final result = await compute(_processIsolate, args);
    if (!mounted) return;
    setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _processIsolate(Map<String, dynamic> args) {
    var image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;
    if (args['isRotate'] as bool) {
      image = img.copyRotate(image, angle: args['angle'] as double);
    } else {
      image = (args['flipH'] as bool)
          ? img.flipHorizontal(image)
          : img.flipVertical(image);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isRotate = _tabs.index == 0;

    return PhotoToolScaffold(
      title: isRotate ? 'Rotate Photo' : 'Mirror / Flip',
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
      processLabel: isRotate ? 'Rotate' : 'Flip',
      processIcon: isRotate ? Icons.rotate_right : Icons.flip_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Column(
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Rotate'), Tab(text: 'Mirror / Flip')],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isRotate
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Angle', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [90.0, 180.0, 270.0, 45.0].map((a) {
                          return ChoiceChip(
                            label: Text('${a.round()}°'),
                            selected: _angle == a,
                            onSelected: (_) => setState(() => _angle = a),
                          );
                        }).toList()),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Custom angle', style: theme.textTheme.bodySmall),
                          Text('${_angle.round()}°', style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary, fontWeight: FontWeight.w600)),
                        ]),
                        Slider(value: _angle, min: 0, max: 360, divisions: 72,
                            onChanged: (v) => setState(() => _angle = v)),
                      ],
                    )
                  : Column(
                      children: [
                        RadioListTile<bool>(
                          title: const Text('Flip Horizontal (Mirror)'),
                          secondary: const Icon(Icons.flip_outlined),
                          value: true,
                          groupValue: _flipH,
                          onChanged: (v) => setState(() => _flipH = v!),
                        ),
                        RadioListTile<bool>(
                          title: const Text('Flip Vertical'),
                          secondary: const Icon(Icons.flip_outlined),
                          value: false,
                          groupValue: _flipH,
                          onChanged: (v) => setState(() => _flipH = v!),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
