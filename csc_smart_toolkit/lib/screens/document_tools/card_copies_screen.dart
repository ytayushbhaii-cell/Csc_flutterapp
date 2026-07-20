import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/card_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/common/card_tool_scaffold.dart';

/// A4 layout with selectable number of card copies (2 / 4 / 6 / 8).
class CardCopiesScreen extends StatefulWidget {
  const CardCopiesScreen({
    super.key,
    required this.title,
    required this.toolId,
    required this.cardType,
    this.initialCopies = 4,
  });

  final String title;
  final String toolId;
  final CardType cardType;
  final int initialCopies;

  @override
  State<CardCopiesScreen> createState() => _CardCopiesScreenState();
}

class _CardCopiesScreenState extends State<CardCopiesScreen>
    with CardToolMixin {
  late int _copies;

  @override
  void initState() {
    super.initState();
    _copies = widget.initialCopies;
  }

  @override
  String get toolId => widget.toolId;
  @override
  String get toolName => widget.title;
  @override
  CardType get cardType => widget.cardType;

  Future<void> _pickImage() async {
    final src = await _sourceDialog();
    if (src == null) return;
    final bytes = await PhotoService.pickImage(source: src);
    if (bytes == null || !mounted) return;
    setState(() {
      originalBytes = bytes;
      resultBytes = null;
    });
  }

  Future<ImageSource?> _sourceDialog() => showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Use Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ]),
        ),
      );

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() {
      isProcessing = true;
      progress = 0.3;
      progressStage = 'Creating A4 layout…';
    });
    final result =
        await CardService.createCopiesLayout(originalBytes!, _copies);
    if (!mounted) return;
    setState(() {
      resultBytes = result;
      isProcessing = false;
      progress = 1.0;
      progressStage = 'Done';
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardToolScaffold(
      title: widget.title,
      cardType: widget.cardType,
      originalBytes: originalBytes,
      resultBytes: resultBytes,
      isProcessing: isProcessing,
      progress: progress,
      progressStage: progressStage,
      onPickImage: _pickImage,
      onProcess: _process,
      onReset: resetResult,
      onSave: saveResult,
      onShare: shareResult,
      processLabel: 'Generate Layout ($_copies copies)',
      processIcon: Icons.grid_on_outlined,
      showBeforeAfter: false,
      controlsSection: originalBytes != null ? _copiesSelector() : null,
    );
  }

  Widget _copiesSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of Copies',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [2, 4, 6, 8].map((n) {
                final selected = _copies == n;
                return ChoiceChip(
                  label: Text('$n copies'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _copies = n;
                    resultBytes = null;
                  }),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
