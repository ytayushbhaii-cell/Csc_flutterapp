import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../services/card_service.dart';
import '../../services/photo_service.dart';

/// Pick front + back of a card and combine them on an A4 sheet.
class CardFrontBackScreen extends StatefulWidget {
  const CardFrontBackScreen({
    super.key,
    required this.title,
    required this.toolId,
    required this.cardType,
  });

  final String title;
  final String toolId;
  final CardType cardType;

  @override
  State<CardFrontBackScreen> createState() => _CardFrontBackScreenState();
}

class _CardFrontBackScreenState extends State<CardFrontBackScreen> {
  Uint8List? _front;
  Uint8List? _back;
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';

  Future<void> _pickFront() async {
    final bytes = await _pick();
    if (bytes == null) return;
    setState(() {
      _front = bytes;
      _result = null;
    });
  }

  Future<void> _pickBack() async {
    final bytes = await _pick();
    if (bytes == null) return;
    setState(() {
      _back = bytes;
      _result = null;
    });
  }

  Future<Uint8List?> _pick() async {
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
    if (src == null) return null;
    return PhotoService.pickImage(source: src);
  }

  Future<void> _process() async {
    if (_front == null || _back == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.4;
      _stage = 'Combining front & back…';
    });
    final result =
        await CardService.createFrontBackLayout(_front!, _back!);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isProcessing = false;
      _progress = 1.0;
      _stage = 'Done';
    });
  }

  Future<void> _save(String format) async {
    final bytes = _result;
    if (bytes == null) return;
    Uint8List toSave;
    String ext;
    if (format == 'pdf') {
      ext = 'pdf';
      toSave = await CardService.toPdf(bytes);
    } else {
      ext = 'png';
      toSave = bytes;
    }
    final name = PhotoService.timestampFilename(widget.toolId, ext);
    final path = await PhotoService.saveToDocuments(toSave, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: widget.toolId,
          toolName: widget.title,
          category: widget.cardType.category);
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename(widget.toolId, 'png');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.cardType.color;
    final canProcess = _front != null && _back != null && !_isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_result != null)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _result = null)),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pick row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _PickSlot(
                  label: 'Front Side',
                  bytes: _front,
                  color: color,
                  onPick: _pickFront,
                )),
                const SizedBox(width: 12),
                Expanded(child: _PickSlot(
                  label: 'Back Side',
                  bytes: _back,
                  color: color,
                  onPick: _pickBack,
                )),
              ],
            ),
            const SizedBox(height: 16),

            // ── Result preview ────────────────────────────────────────
            if (_result != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.memory(_result!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Progress ──────────────────────────────────────────────
            if (_isProcessing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(_stage),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions ───────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_result == null)
                FilledButton.icon(
                  icon: const Icon(Icons.merge_outlined),
                  label: const Text('Combine on A4'),
                  onPressed: canProcess ? _process : null,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                )
              else ...[
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Save PDF'),
                      onPressed: () => _save('pdf'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Save PNG'),
                      onPressed: () => _save('png'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _share,
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

class _PickSlot extends StatelessWidget {
  const _PickSlot({
    required this.label,
    required this.bytes,
    required this.color,
    required this.onPick,
  });
  final String label;
  final Uint8List? bytes;
  final Color color;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: SizedBox(
          height: 150,
          child: bytes != null
              ? Stack(fit: StackFit.expand, children: [
                  Image.memory(bytes!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center),
                ]),
        ),
      ),
    );
  }
}
