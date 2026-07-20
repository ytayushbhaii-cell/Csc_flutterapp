import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/ocr_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  String _sourceName = '';
  String _extractedText = '';
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';

  Future<void> _pickImage() async {
    final bytes = await PhotoService.pickImage();
    if (bytes == null) return;
    await _runOcrOnImages([bytes], 'Image');
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.first;
    if (pf.path == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.1;
      _stage = 'Rendering PDF pages…';
      _sourceName = pf.name;
      _extractedText = '';
    });
    final pdfBytes = await File(pf.path!).readAsBytes();
    final pages = await PDFService.pdfToImages(pdfBytes, dpi: 150);
    if (!mounted) return;
    await _runOcrOnImages(pages, pf.name);
  }

  Future<void> _runOcrOnImages(List<Uint8List> images, String name) async {
    setState(() {
      _isProcessing = true;
      _stage = 'Extracting text…';
      _sourceName = name;
      _extractedText = '';
    });
    try {
      String text;
      if (images.length == 1) {
        setState(() { _progress = 0.5; });
        text = await OCRService.extractFromImage(images.first);
      } else {
        text = '';
        for (var i = 0; i < images.length; i++) {
          if (!mounted) return;
          setState(() {
            _stage = 'OCR page ${i + 1}/${images.length}…';
            _progress = (i + 1) / images.length * 0.9;
          });
          final part = await OCRService.extractFromImage(images[i]);
          if (i > 0) text += '\n\n── Page ${i + 1} ──\n\n';
          text += part;
        }
      }
      if (!mounted) return;
      setState(() {
        _extractedText = text.trim();
        _isProcessing = false;
        _progress = 1.0;
        _stage = 'Done';
      });
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-ocr', toolName: 'PDF OCR', category: 'PDF Tools');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extractedText = 'Error: $e';
        _isProcessing = false;
        _stage = '';
      });
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _extractedText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  Future<void> _exportTxt() async {
    if (_extractedText.isEmpty) return;
    final name = PhotoService.timestampFilename('ocr_text', 'txt');
    final path = await PhotoService.saveToDocuments(
        Uint8List.fromList(_extractedText.codeUnits), name);
    if (mounted) PhotoService.showSavedSnackbar(context, path);
  }

  Future<void> _shareText() async {
    if (_extractedText.isEmpty) return;
    final name = PhotoService.timestampFilename('ocr_text', 'txt');
    await PhotoService.shareBytes(
        Uint8List.fromList(_extractedText.codeUnits), name);
  }

  void _reset() => setState(() {
        _extractedText = '';
        _sourceName = '';
        _stage = '';
        _progress = 0;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFDC2626);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR (Offline)'),
        actions: [
          if (_extractedText.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _reset),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Source info ─────────────────────────────────────────
            if (_sourceName.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.file_present_outlined, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_sourceName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium)),
                  ]),
                ),
              ),

            // ── Pick buttons ─────────────────────────────────────────
            if (_extractedText.isEmpty && !_isProcessing) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Pick Image'),
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Pick PDF'),
                    onPressed: _pickPdf,
                    style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Icon(Icons.document_scanner_outlined,
                        size: 36, color: color),
                    const SizedBox(height: 8),
                    Text('Offline OCR',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'Extracts text from images and PDFs entirely on-device. '
                        'No internet required.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline)),
                  ]),
                ),
              ),
            ],

            // ── Progress ─────────────────────────────────────────────
            if (_isProcessing) ...[
              const SizedBox(height: 12),
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
            ],

            // ── Extracted text ────────────────────────────────────────
            if (_extractedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Action row
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    onPressed: _copyText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.text_snippet_outlined, size: 16),
                    label: const Text('Export TXT'),
                    onPressed: _exportTxt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share'),
                    onPressed: _shareText,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // Text display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${_extractedText.split('\n').length} lines  •  '
                              '${_extractedText.length} chars',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline)),
                          TextButton(
                              onPressed: _pickImage,
                              child: const Text('Try another')),
                        ],
                      ),
                      const Divider(),
                      SelectableText(
                        _extractedText.isEmpty
                            ? '(No text detected)'
                            : _extractedText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace', height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
