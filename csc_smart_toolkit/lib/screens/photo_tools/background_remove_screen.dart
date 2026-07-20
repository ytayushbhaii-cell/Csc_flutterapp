import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/photo_result.dart';
import '../../services/background_remove_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

class BackgroundRemoveScreen extends StatefulWidget {
  const BackgroundRemoveScreen({super.key});

  @override
  State<BackgroundRemoveScreen> createState() =>
      _BackgroundRemoveScreenState();
}

class _BackgroundRemoveScreenState extends State<BackgroundRemoveScreen>
    with PhotoToolMixin {
  BgFill _selectedFill = BgFill.transparent;
  int _threshold = 40;

  @override
  String get toolIdBase => 'bg-remove';
  @override
  String get toolNameBase => 'Background Remove';

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() {
      isProcessing = true;
      progress = 0;
      progressStage = bgRemoveStages[0].label;
    });

    // Animate through stages while processing
    const stages = bgRemoveStages;
    int stageIdx = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      stageIdx++;
      if (stageIdx < stages.length - 1 && mounted) {
        setState(() {
          progress = stages[stageIdx].progress;
          progressStage = stages[stageIdx].label;
        });
      } else {
        t.cancel();
      }
    });

    try {
      final result = await BackgroundRemoveService.removeBackground(
        originalBytes!,
        threshold: _threshold,
        fill: _selectedFill,
      );
      timer.cancel();
      if (!mounted) return;
      setState(() {
        resultBytes = result;
        isProcessing = false;
        progress = 1.0;
        progressStage = stages.last.label;
      });
      context.read<HistoryProvider>().recordUsage(
            toolId: toolIdBase,
            toolName: toolNameBase,
            category: 'Photo Tools',
          );
    } catch (e) {
      timer.cancel();
      if (!mounted) return;
      setState(() { isProcessing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PhotoToolScaffold(
      title: 'Background Remove',
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
      processLabel: 'Remove Background',
      processIcon: Icons.auto_fix_high_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Output format
              Text('Output',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _FillChip(
                    label: 'Transparent',
                    icon: Icons.layers_clear_outlined,
                    color: const Color(0xFF64748B),
                    selected: _selectedFill == BgFill.transparent,
                    onTap: () => setState(() => _selectedFill = BgFill.transparent),
                  ),
                  _FillChip(
                    label: 'White',
                    icon: Icons.wb_sunny_outlined,
                    color: const Color(0xFF374151),
                    selected: _selectedFill == BgFill.white,
                    onTap: () => setState(() => _selectedFill = BgFill.white),
                  ),
                  _FillChip(
                    label: 'Blue',
                    icon: Icons.water_outlined,
                    color: const Color(0xFF2563EB),
                    selected: _selectedFill == BgFill.blue,
                    onTap: () => setState(() => _selectedFill = BgFill.blue),
                  ),
                  _FillChip(
                    label: 'Red',
                    icon: Icons.circle_outlined,
                    color: const Color(0xFFDC2626),
                    selected: _selectedFill == BgFill.red,
                    onTap: () => setState(() => _selectedFill = BgFill.red),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Threshold slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sensitivity',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('$_threshold',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              Slider(
                value: _threshold.toDouble(),
                min: 10,
                max: 80,
                divisions: 14,
                label: _threshold.toString(),
                onChanged: (v) => setState(() => _threshold = v.round()),
              ),
              Text(
                'Higher = removes more pixels (use for solid backgrounds)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withAlpha(140)),
              ),
              const SizedBox(height: 12),
              // Stage preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bgRemoveStages
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              Icon(Icons.check_circle_outline,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(s.label,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: cs.onSurface.withAlpha(160))),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FillChip extends StatelessWidget {
  const _FillChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
          fontWeight: FontWeight.w500),
      checkmarkColor: Colors.white,
      showCheckmark: false,
    );
  }
}
