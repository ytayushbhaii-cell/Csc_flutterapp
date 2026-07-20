import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../services/photo_service.dart';

/// Common scaffold for every photo tool.
/// Provides: pick image, before/after preview, progress indicator,
/// save, share, reset actions.
class PhotoToolScaffold extends StatelessWidget {
  const PhotoToolScaffold({
    super.key,
    required this.title,
    required this.toolId,
    required this.category,
    required this.originalBytes,
    required this.resultBytes,
    required this.isProcessing,
    required this.progress,
    required this.progressStage,
    required this.onPickImage,
    required this.onProcess,
    required this.onReset,
    required this.onSave,
    required this.onShare,
    this.processLabel = 'Process',
    this.processIcon = Icons.auto_fix_high_outlined,
    this.controlsSection,
    this.canProcess = true,
  });

  final String title;
  final String toolId;
  final String category;
  final Uint8List? originalBytes;
  final Uint8List? resultBytes;
  final bool isProcessing;
  final double progress;
  final String progressStage;
  final VoidCallback onPickImage;
  final VoidCallback onProcess;
  final VoidCallback onReset;
  final Future<void> Function(String format) onSave;
  final VoidCallback onShare;
  final String processLabel;
  final IconData processIcon;
  final Widget? controlsSection;
  final bool canProcess;

  @override
  Widget build(BuildContext context) {
    final hasImage = originalBytes != null;
    final hasResult = resultBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (hasResult)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: onReset,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image Preview ────────────────────────────────────────────
            if (!hasImage)
              _PickImageCard(onPick: onPickImage)
            else
              _PreviewCard(
                original: originalBytes!,
                result: resultBytes,
                showSplit: hasResult,
              ),
            const SizedBox(height: 16),

            // ── Controls Section ─────────────────────────────────────────
            if (hasImage && controlsSection != null) ...[
              controlsSection!,
              const SizedBox(height: 16),
            ],

            // ── Progress ─────────────────────────────────────────────────
            if (isProcessing) ...[
              _ProgressCard(progress: progress, stage: progressStage),
              const SizedBox(height: 16),
            ],

            // ── Action Buttons ───────────────────────────────────────────
            if (hasImage && !isProcessing) ...[
              // Pick new image
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Change Image'),
                onPressed: onPickImage,
              ),
              const SizedBox(height: 10),

              // Process
              if (!hasResult || canProcess)
                FilledButton.icon(
                  icon: Icon(processIcon),
                  label: Text(processLabel),
                  onPressed: canProcess ? onProcess : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

              // Save / Share
              if (hasResult) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Save PNG'),
                        onPressed: () => onSave('png'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Save JPG'),
                        onPressed: () => onSave('jpg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onShare,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _PickImageCard extends StatelessWidget {
  const _PickImageCard({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withAlpha(80),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text('Tap to Import Image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Gallery or Camera',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withAlpha(140))),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.original,
    required this.result,
    required this.showSplit,
  });
  final Uint8List original;
  final Uint8List? result;
  final bool showSplit;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard>
    with SingleTickerProviderStateMixin {
  bool _showResult = true;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    if (widget.result != null) _anim.forward();
  }

  @override
  void didUpdateWidget(_PreviewCard old) {
    super.didUpdateWidget(old);
    if (widget.result != null && old.result == null) _anim.forward();
    if (widget.result == null) _anim.reverse();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Toggle
          if (widget.showSplit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Before', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  Switch.adaptive(
                    value: _showResult,
                    onChanged: (v) => setState(() => _showResult = v),
                    activeColor: cs.primary,
                  ),
                  const Spacer(),
                  const Text('After', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

          // Image
          SizedBox(
            height: 280,
            width: double.infinity,
            child: FadeTransition(
              opacity: _fade,
              child: widget.result != null && _showResult
                  ? Image.memory(widget.result!, fit: BoxFit.contain)
                  : Image.memory(widget.original, fit: BoxFit.contain),
            ),
          ),

          if (widget.showSplit)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _showResult ? 'After processing' : 'Original',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurface.withAlpha(140)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.stage});
  final double progress;
  final String stage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(stage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin providing common photo-tool state management.
mixin PhotoToolMixin<T extends StatefulWidget> on State<T> {
  Uint8List? originalBytes;
  Uint8List? resultBytes;
  bool isProcessing = false;
  double progress = 0;
  String progressStage = '';

  Future<void> pickImageBase() async {
    final bytes = await PhotoService.pickImage();
    if (bytes == null) return;
    setState(() {
      originalBytes = bytes;
      resultBytes = null;
      progress = 0;
      progressStage = '';
    });
  }

  void resetBase() => setState(() {
        resultBytes = null;
        progress = 0;
        progressStage = '';
      });

  Future<void> saveBase(String format) async {
    final bytes = resultBytes;
    if (bytes == null || !mounted) return;
    final ext = format == 'png' ? 'png' : 'jpg';
    final filename =
        PhotoService.timestampFilename('csc_photo', ext);
    final path = await PhotoService.saveToDocuments(bytes, filename);
    if (mounted) PhotoService.showSavedSnackbar(context, path);
    // Record history
    if (mounted) {
      context.read<HistoryProvider>().recordUsage(
            toolId: toolIdBase,
            toolName: toolNameBase,
            category: 'Photo Tools',
          );
    }
  }

  Future<void> shareBase() async {
    final bytes = resultBytes;
    if (bytes == null) return;
    final filename =
        PhotoService.timestampFilename('csc_photo', 'png');
    await PhotoService.shareBytes(bytes, filename);
  }

  String get toolIdBase;
  String get toolNameBase;
}
