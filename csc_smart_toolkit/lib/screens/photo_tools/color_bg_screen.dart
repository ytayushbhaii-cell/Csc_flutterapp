import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/background_remove_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// White / Blue / Red Background screen.
/// [bgFill] determines which background color to apply.
class ColorBgScreen extends StatefulWidget {
  const ColorBgScreen({super.key, required this.bgFill});
  final BgFill bgFill;
  @override
  State<ColorBgScreen> createState() => _ColorBgScreenState();
}

class _ColorBgScreenState extends State<ColorBgScreen> with PhotoToolMixin {
  int _threshold = 40;

  String get _colorName {
    switch (widget.bgFill) {
      case BgFill.white: return 'White';
      case BgFill.blue: return 'Blue';
      case BgFill.red: return 'Red';
      default: return 'Color';
    }
  }

  Color get _previewColor {
    switch (widget.bgFill) {
      case BgFill.white: return const Color(0xFFFFFFFF);
      case BgFill.blue: return const Color(0xFF1D4ED8);
      case BgFill.red: return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  @override
  String get toolIdBase => '${_colorName.toLowerCase()}-bg';
  @override
  String get toolNameBase => '$_colorName Background';

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.2; progressStage = 'Removing background…'; });
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() { progress = 0.6; progressStage = 'Applying $_colorName background…'; });
      final result = await BackgroundRemoveService.removeBackground(
        originalBytes!,
        threshold: _threshold,
        fill: widget.bgFill,
      );
      if (!mounted) return;
      setState(() { resultBytes = result; isProcessing = false; progress = 1.0; progressStage = 'Done'; });
      context.read<HistoryProvider>().recordUsage(
          toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
    } catch (e) {
      if (!mounted) return;
      setState(() { isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PhotoToolScaffold(
      title: '$_colorName Background',
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
      processLabel: 'Apply $_colorName Background',
      processIcon: Icons.format_color_fill_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _previewColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outline.withAlpha(60)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$_colorName Background',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Sensitivity', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('$_threshold', style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
              Slider(value: _threshold.toDouble(), min: 10, max: 80, divisions: 14,
                  label: '$_threshold',
                  onChanged: (v) => setState(() => _threshold = v.round())),
              Text('Higher = removes more of the background',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(140))),
            ],
          ),
        ),
      ),
    );
  }
}
