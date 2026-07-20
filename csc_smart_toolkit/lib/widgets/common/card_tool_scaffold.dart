import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../services/card_service.dart';
import '../../services/photo_service.dart';

// ── Mixin ──────────────────────────────────────────────────────────────────

mixin CardToolMixin<T extends StatefulWidget> on State<T> {
  Uint8List? originalBytes;
  Uint8List? resultBytes;
  bool isProcessing = false;
  double progress = 0.0;
  String progressStage = '';

  // Subclass provides these
  String get toolId;
  String get toolName;
  CardType get cardType;

  void resetResult() {
    setState(() {
      resultBytes = null;
      progress = 0.0;
      progressStage = '';
    });
  }

  /// Save result (or original) to disk. [format] = 'png' | 'jpg' | 'pdf'.
  Future<void> saveResult(String format) async {
    final bytes = resultBytes ?? originalBytes;
    if (bytes == null) return;

    Uint8List toSave;
    String ext;
    if (format == 'pdf') {
      ext = 'pdf';
      toSave = await CardService.toPdf(bytes);
    } else if (format == 'jpg') {
      ext = 'jpg';
      toSave = bytes;
    } else {
      ext = 'png';
      toSave = bytes;
    }

    final name = PhotoService.timestampFilename(toolId, ext);
    final path = await PhotoService.saveToDocuments(toSave, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: toolId,
          toolName: toolName,
          category: cardType.category);
    }
  }

  Future<void> shareResult() async {
    final bytes = resultBytes ?? originalBytes;
    if (bytes == null) return;
    final name = PhotoService.timestampFilename(toolId, 'png');
    await PhotoService.shareBytes(bytes, name);
  }
}

// ── Scaffold widget ────────────────────────────────────────────────────────

class CardToolScaffold extends StatelessWidget {
  const CardToolScaffold({
    super.key,
    required this.title,
    required this.cardType,
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
    this.showBeforeAfter = false,
  });

  final String title;
  final CardType cardType;
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
  final bool showBeforeAfter;

  @override
  Widget build(BuildContext context) {
    final hasImage = originalBytes != null;
    final hasResult = resultBytes != null;
    final color = cardType.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (hasResult)
            IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset',
                onPressed: onReset),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview ────────────────────────────────────────────────
            if (!hasImage)
              _PickCard(onPick: onPickImage, color: color)
            else
              _PreviewCard(
                original: originalBytes!,
                result: resultBytes,
                showToggle: showBeforeAfter && hasResult,
              ),
            const SizedBox(height: 16),

            // ── Controls ───────────────────────────────────────────────
            if (hasImage && controlsSection != null) ...[
              controlsSection!,
              const SizedBox(height: 16),
            ],

            // ── Progress ───────────────────────────────────────────────
            if (isProcessing) ...[
              _ProgressCard(progress: progress, stage: progressStage),
              const SizedBox(height: 16),
            ],

            // ── Buttons ────────────────────────────────────────────────
            if (hasImage && !isProcessing) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Change Image'),
                onPressed: onPickImage,
              ),
              const SizedBox(height: 10),
              if (!hasResult || canProcess)
                FilledButton.icon(
                  icon: Icon(processIcon),
                  label: Text(processLabel),
                  onPressed: canProcess ? onProcess : null,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              if (hasResult) ...[
                const SizedBox(height: 10),
                // Save buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Save PDF'),
                        onPressed: () => onSave('pdf'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Save PNG'),
                        onPressed: () => onSave('png'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: onShare,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Internal widgets ───────────────────────────────────────────────────────

class _PickCard extends StatelessWidget {
  const _PickCard({required this.onPick, required this.color});
  final VoidCallback onPick;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle),
                child: Icon(Icons.add_photo_alternate_outlined,
                    color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text('Tap to pick image',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Gallery or Camera',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.original,
    required this.result,
    required this.showToggle,
  });
  final Uint8List original;
  final Uint8List? result;
  final bool showToggle;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  bool _showResult = true;

  @override
  void didUpdateWidget(_PreviewCard old) {
    super.didUpdateWidget(old);
    if (widget.result != null && old.result == null) {
      _showResult = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes =
        (widget.result != null && _showResult) ? widget.result! : widget.original;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          if (widget.showToggle && widget.result != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Original')),
                  ButtonSegment(value: true, label: Text('Result')),
                ],
                selected: {_showResult},
                onSelectionChanged: (s) =>
                    setState(() => _showResult = s.first),
                showSelectedIcon: false,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(stage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
