import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/card_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/common/card_tool_scaffold.dart';

/// Generic crop screen for Aadhaar, PAN, Voter, DL, and Passport cards.
class CardCropScreen extends StatefulWidget {
  const CardCropScreen({
    super.key,
    required this.title,
    required this.toolId,
    required this.cardType,
    this.processLabel = 'Crop to Card Size',
  });

  final String title;
  final String toolId;
  final CardType cardType;
  final String processLabel;

  @override
  State<CardCropScreen> createState() => _CardCropScreenState();
}

class _CardCropScreenState extends State<CardCropScreen>
    with CardToolMixin {
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
      progressStage = 'Cropping to card size…';
    });
    final result = await CardService.cropCard(originalBytes!);
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
      processLabel: widget.processLabel,
      processIcon: Icons.crop_outlined,
      showBeforeAfter: resultBytes != null,
    );
  }
}
