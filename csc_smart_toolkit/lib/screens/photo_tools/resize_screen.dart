import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../services/photo_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

class ResizeScreen extends StatefulWidget {
  const ResizeScreen({super.key});
  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> with PhotoToolMixin {
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  bool _keepAspect = true;
  int _originalW = 0, _originalH = 0;

  @override
  String get toolIdBase => 'photo-resize';
  @override
  String get toolNameBase => 'Photo Resize';

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Future<void> pickImageBase() async {
    final bytes = await PhotoService.pickImage();
    if (bytes == null) return;
    final decoded = img.decodeImage(bytes);
    setState(() {
      originalBytes = bytes;
      resultBytes = null;
      if (decoded != null) {
        _originalW = decoded.width;
        _originalH = decoded.height;
        _wCtrl.text = '${decoded.width}';
        _hCtrl.text = '${decoded.height}';
      }
    });
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    final w = int.tryParse(_wCtrl.text) ?? 0;
    final h = int.tryParse(_hCtrl.text) ?? 0;
    if (w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid width and height')),
      );
      return;
    }
    setState(() { isProcessing = true; progress = 0.3; progressStage = 'Resizing…'; });
    final result = await compute(_resizeIsolate, {'bytes': originalBytes!, 'w': w, 'h': h});
    if (!mounted) return;
    setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _resizeIsolate(Map<String, dynamic> args) {
    final image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;
    final resized = img.copyResize(image, width: args['w'] as int, height: args['h'] as int,
        interpolation: img.Interpolation.cubic);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
  }

  void _onWidthChanged(String v) {
    if (!_keepAspect || _originalW == 0) return;
    final w = int.tryParse(v);
    if (w != null && w > 0) {
      _hCtrl.text = (w * _originalH / _originalW).round().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PhotoToolScaffold(
      title: 'Photo Resize',
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
      processLabel: 'Resize',
      processIcon: Icons.photo_size_select_large_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dimensions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _wCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Width (px)', suffixText: 'px'),
                    onChanged: _onWidthChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Height (px)', suffixText: 'px'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Keep Aspect Ratio'),
                value: _keepAspect,
                onChanged: (v) => setState(() => _keepAspect = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
