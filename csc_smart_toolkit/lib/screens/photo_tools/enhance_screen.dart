import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// Photo Enhance — Brightness / Contrast / Sharpen / Saturation.
/// [initialTab]: 0=All, 1=Brightness, 2=Contrast, 3=Sharpen
class EnhanceScreen extends StatefulWidget {
  const EnhanceScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen>
    with PhotoToolMixin, SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Sliders (all centred at 0.0)
  double _brightness = 0;  // -1.0 to 1.0
  double _contrast = 0;    // -1.0 to 1.0
  double _saturation = 0;  // -1.0 to 1.0
  double _sharpen = 0;     // 0.0 to 1.0

  @override
  String get toolIdBase => 'enhance';
  @override
  String get toolNameBase => 'Photo Enhance';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.3; progressStage = 'Enhancing…'; });
    final args = {
      'bytes': originalBytes!,
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
      'sharpen': _sharpen,
    };
    final result = await compute(_enhanceIsolate, args);
    if (!mounted) return;
    setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
    context.read<HistoryProvider>().recordUsage(
        toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
  }

  static Uint8List _enhanceIsolate(Map<String, dynamic> args) {
    var image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;

    final brightness = (args['brightness'] as double);
    final contrast = (args['contrast'] as double);
    final saturation = (args['saturation'] as double);
    final sharpen = (args['sharpen'] as double);

    // adjustColor uses multipliers: 1.0 = no change
    if (brightness != 0 || contrast != 0 || saturation != 0) {
      image = img.adjustColor(
        image,
        brightness: brightness,
        contrast: contrast == 0 ? null : 1.0 + contrast,
        saturation: saturation == 0 ? null : 1.0 + saturation,
      );
    }

    // Sharpen via convolution
    if (sharpen > 0.05) {
      final k = sharpen * 2.0;
      image = img.convolution(image, filter: [
        0, -k, 0,
        -k, 1 + 4 * k, -k,
        0, -k, 0,
      ], div: 1, offset: 0);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  void _resetSliders() => setState(() {
        _brightness = 0;
        _contrast = 0;
        _saturation = 0;
        _sharpen = 0;
        resultBytes = null;
      });

  @override
  Widget build(BuildContext context) {
    return PhotoToolScaffold(
      title: 'Photo Enhance',
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
      processLabel: 'Apply Enhancements',
      processIcon: Icons.auto_fix_high_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SliderRow(
                icon: Icons.brightness_6_outlined,
                iconColor: const Color(0xFFF59E0B),
                label: 'Brightness',
                value: _brightness,
                min: -1, max: 1,
                onChanged: (v) => setState(() => _brightness = v),
              ),
              const SizedBox(height: 8),
              _SliderRow(
                icon: Icons.contrast,
                iconColor: const Color(0xFF0891B2),
                label: 'Contrast',
                value: _contrast,
                min: -1, max: 1,
                onChanged: (v) => setState(() => _contrast = v),
              ),
              const SizedBox(height: 8),
              _SliderRow(
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Saturation',
                value: _saturation,
                min: -1, max: 1,
                onChanged: (v) => setState(() => _saturation = v),
              ),
              const SizedBox(height: 8),
              _SliderRow(
                icon: Icons.deblur_outlined,
                iconColor: const Color(0xFF6366F1),
                label: 'Sharpen',
                value: _sharpen,
                min: 0, max: 1,
                onChanged: (v) => setState(() => _sharpen = v),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All'),
                onPressed: _resetSliders,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;
  final double min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';
    return Row(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(width: 8),
      SizedBox(
        width: 72,
        child: Text(label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Slider(value: value, min: min, max: max,
            onChanged: onChanged, activeColor: iconColor),
      ),
      SizedBox(
        width: 36,
        child: Text('$sign${(value * 100).round()}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: iconColor, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
