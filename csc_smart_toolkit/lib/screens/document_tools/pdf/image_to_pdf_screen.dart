import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class ImageToPDFScreen extends StatefulWidget {
  const ImageToPDFScreen({super.key});

  @override
  State<ImageToPDFScreen> createState() => _ImageToPDFScreenState();
}

class _ImageToPDFScreenState extends State<ImageToPDFScreen> {
  final List<Uint8List> _images = [];
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  PdfPageFormat _format = PdfPageFormat.a4;

  Future<void> _addImages() async {
    final images = await PhotoService.pickMultipleImages();
    if (images.isEmpty) return;
    setState(() {
      _images.addAll(images);
      _result = null;
    });
  }

  void _remove(int i) => setState(() {
        _images.removeAt(i);
        _result = null;
      });

  void _moveUp(int i) {
    if (i <= 0) return;
    setState(() {
      final tmp = _images[i];
      _images[i] = _images[i - 1];
      _images[i - 1] = tmp;
      _result = null;
    });
  }

  void _moveDown(int i) {
    if (i >= _images.length - 1) return;
    setState(() {
      final tmp = _images[i];
      _images[i] = _images[i + 1];
      _images[i + 1] = tmp;
      _result = null;
    });
  }

  Future<void> _create() async {
    if (_images.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.3;
      _stage = 'Building PDF…';
    });
    final result =
        await PDFService.imagesToPdf(_images, format: _format);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isProcessing = false;
      _progress = 1.0;
      _stage = 'Done';
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('images_to_pdf', 'pdf');
    final path = await PhotoService.saveToDocuments(_result!, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-from-image',
          toolName: 'Image to PDF',
          category: 'PDF Tools');
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('images_to_pdf', 'pdf');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
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
            // ── Add images ───────────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Images'),
              onPressed: _isProcessing ? null : _addImages,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),

            // ── Image list ───────────────────────────────────────────
            if (_images.isNotEmpty) ...[
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < _images.length; i++)
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(_images[i],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover),
                        ),
                        title: Text('Image ${i + 1}',
                            style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                            '${(_images[i].length / 1024).toStringAsFixed(0)} KB'),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: i > 0 ? () => _moveUp(i) : null),
                          IconButton(
                              icon:
                                  const Icon(Icons.arrow_downward, size: 18),
                              onPressed: i < _images.length - 1
                                  ? () => _moveDown(i)
                                  : null),
                          IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _remove(i)),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Page format ──────────────────────────────────────────
            if (_images.isNotEmpty && _result == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Page size',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<PdfPageFormat>(
                        segments: const [
                          ButtonSegment(
                              value: PdfPageFormat.a4, label: Text('A4')),
                          ButtonSegment(
                              value: PdfPageFormat.letter,
                              label: Text('Letter')),
                        ],
                        selected: {_format},
                        onSelectionChanged: (s) =>
                            setState(() => _format = s.first),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Progress ─────────────────────────────────────────────
            if (_isProcessing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(_stage),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Result ───────────────────────────────────────────────
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                        'PDF ready  •  ${_images.length} pages  •  '
                        '${(_result!.length / 1024).toStringAsFixed(0)} KB',
                        style: theme.textTheme.bodyMedium),
                  ]),
                ),
              ),
            const SizedBox(height: 12),

            // ── Buttons ───────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_images.isNotEmpty && _result == null)
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Create PDF (${_images.length} pages)'),
                  onPressed: _create,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              if (_result != null) ...[
                Row(children: [
                  Expanded(
                      child: FilledButton.icon(
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Save'),
                          onPressed: _save)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FilledButton.tonal(
                          onPressed: _share,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ))),
                ]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
