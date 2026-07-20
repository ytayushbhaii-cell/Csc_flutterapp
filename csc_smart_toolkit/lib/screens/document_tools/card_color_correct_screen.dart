import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/card_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/common/card_tool_scaffold.dart';

/// Auto color-correction for scanned card images.
class CardColorCorrectScreen extends StatefulWidget {
  const CardColorCorrectScreen({
    super.key,
    required this.title,
    required this.toolId,
    required this.cardType,
  });

  final String title;
  final String toolId;
  final CardType cardType;

  @override
  State<CardColorCorrectScreen> createState() =>
      _CardColorCorrectScreenState();
}

class _CardColorCorrectScreenState extends State<CardColorCorrectScreen>
    with CardToolMixin {
  @override
  String get toolId => widget.toolId;
  @override
  String get toolName => widget.title;
  @override
  CardType get cardType => widget.cardType;

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
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
    if (src == null) return;
    final bytes = await PhotoService.pickImage(source: src);
    if (bytes == null || !mounted) return;
    setState(() {
      originalBytes = bytes;
      resultBytes = null;
    });
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() {
      isProcessing = true;
      progress = 0.4;
      progressStage = 'Applying color correction…';
    });
    final result = await CardService.colorCorrect(originalBytes!);
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
      processLabel: 'Auto Correct',
      processIcon: Icons.color_lens_outlined,
      showBeforeAfter: resultBytes != null,
    );
  }
}
