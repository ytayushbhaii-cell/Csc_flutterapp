import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../services/card_service.dart';
import '../../services/pdf_service.dart';
import '../../services/photo_service.dart';

/// Extract a card image from a PDF, then crop to standard card size.
class CardFromPdfScreen extends StatefulWidget {
  const CardFromPdfScreen({
    super.key,
    required this.title,
    required this.toolId,
    required this.cardType,
  });

  final String title;
  final String toolId;
  final CardType cardType;

  @override
  State<CardFromPdfScreen> createState() => _CardFromPdfScreenState();
}

class _CardFromPdfScreenState extends State<CardFromPdfScreen> {
  List<Uint8List> _pages = [];
  int _selectedPage = 0;
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  String _pdfName = '';

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.first;
    final path = pf.path;
    if (path == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.2;
      _stage = 'Rendering PDF pages…';
      _pdfName = pf.name;
      _pages = [];
      _result = null;
    });

    final bytes = await File(path).readAsBytes();
    final pages = await PDFService.pdfToImages(bytes, dpi: 150);
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _selectedPage = 0;
      _isProcessing = false;
      _progress = 1.0;
      _stage = '';
    });
  }

  Future<void> _process() async {
    if (_pages.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.4;
      _stage = 'Cropping to card size…';
    });
    final img = _pages[_selectedPage];
    final result = await CardService.cropCard(img);
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
    final name =
        PhotoService.timestampFilename(widget.toolId, ext);
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
    final name =
        PhotoService.timestampFilename(widget.toolId, 'png');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.cardType.color;
    final theme = Theme.of(context);

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
            // ── PDF Pick ─────────────────────────────────────────────
            Card(
              child: InkWell(
                onTap: _pickPdf,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_outlined,
                        color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pdfName.isEmpty
                            ? 'Tap to pick PDF file'
                            : _pdfName,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.upload_file_outlined),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Page selector ────────────────────────────────────────
            if (_pages.isNotEmpty && _result == null) ...[
              Text('Select Page (${_pages.length} pages)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setState(() => _selectedPage = i),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedPage == i
                              ? color
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(_pages[i],
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Result ───────────────────────────────────────────────
            if (_result != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Image.memory(_result!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
            ],

            // ── Buttons ──────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_pages.isNotEmpty && _result == null)
                FilledButton.icon(
                  icon: const Icon(Icons.crop_outlined),
                  label: const Text('Crop to Card Size'),
                  onPressed: _process,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              if (_result != null) ...[
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
