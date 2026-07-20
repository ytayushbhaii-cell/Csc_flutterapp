import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/background_remove_service.dart';
import '../../services/photo_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// Transparent PNG — removes background and exports as PNG with alpha channel.
class TransparentPngScreen extends StatefulWidget {
  const TransparentPngScreen({super.key});
  @override
  State<TransparentPngScreen> createState() => _TransparentPngScreenState();
}

class _TransparentPngScreenState extends State<TransparentPngScreen>
    with PhotoToolMixin {
  int _threshold = 40;

  @override
  String get toolIdBase => 'transparent-png';
  @override
  String get toolNameBase => 'Transparent PNG';

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.2; progressStage = 'Analyzing image…'; });
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() { progress = 0.6; progressStage = 'Removing background…'; });
      final result = await BackgroundRemoveService.removeBackground(
        originalBytes!,
        threshold: _threshold,
        fill: BgFill.transparent,
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
  Future<void> saveBase(String format) async {
    // Transparent PNG always saves as PNG regardless of format choice
    final bytes = resultBytes;
    if (bytes == null || !mounted) return;
    final filename = PhotoService.timestampFilename('transparent', 'png');
    final path = await PhotoService.saveToDocuments(bytes, filename);
    if (mounted) PhotoService.showSavedSnackbar(context, path);
    if (mounted) {
      context.read<HistoryProvider>().recordUsage(
            toolId: toolIdBase, toolName: toolNameBase, category: 'Photo Tools');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PhotoToolScaffold(
      title: 'Transparent PNG',
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
      processLabel: 'Make Transparent',
      processIcon: Icons.layers_clear_outlined,
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outline.withAlpha(80)),
                    image: const DecorationImage(
                      image: AssetImage('assets/splash_logo.png'),
                      fit: BoxFit.none,
                      repeat: ImageRepeat.repeat,
                      opacity: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Output: PNG with transparency',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Works best with solid-color backgrounds. Result is always exported as PNG.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
