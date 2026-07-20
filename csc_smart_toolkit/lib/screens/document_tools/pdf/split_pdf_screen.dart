import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class SplitPDFScreen extends StatefulWidget {
  const SplitPDFScreen({super.key});

  @override
  State<SplitPDFScreen> createState() => _SplitPDFScreenState();
}

class _SplitPDFScreenState extends State<SplitPDFScreen> {
  Uint8List? _pdfBytes;
  String _pdfName = '';
  int _pageCount = 0;
  int _splitAfter = 1;
  List<Uint8List> _parts = [];
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';

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
      _stage = 'Counting pages…';
      _progress = 0;
      _parts = [];
    });
    final bytes = await File(pf.path!).readAsBytes();
    final count = await PDFService.getPageCount(bytes);
    if (!mounted) return;
    setState(() {
      _pdfBytes = bytes;
      _pdfName = pf.name;
      _pageCount = count;
      _splitAfter = (count / 2).floor().clamp(1, count - 1);
      _isProcessing = false;
      _progress = 1.0;
      _stage = '';
    });
  }

  Future<void> _split() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0;
      _stage = 'Splitting PDF…';
    });
    final parts = await PDFService.splitPdf(_pdfBytes!, _splitAfter);
    if (!mounted) return;
    setState(() {
      _parts = parts;
      _isProcessing = false;
      _progress = 1.0;
      _stage = 'Done';
    });
  }

  Future<void> _savePart(int index) async {
    if (index >= _parts.length) return;
    final name = PhotoService.timestampFilename('split_part${index + 1}', 'pdf');
    final path = await PhotoService.saveToDocuments(_parts[index], name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-split', toolName: 'Split PDF', category: 'PDF Tools');
    }
  }

  Future<void> _sharePart(int index) async {
    if (index >= _parts.length) return;
    final name = PhotoService.timestampFilename('split_part${index + 1}', 'pdf');
    await PhotoService.shareBytes(_parts[index], name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
        actions: [
          if (_parts.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _parts = [])),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pick ────────────────────────────────────────────────
            Card(
              child: InkWell(
                onTap: _isProcessing ? null : _pickPdf,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFFDC2626), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            _pdfName.isEmpty ? 'Tap to pick PDF' : _pdfName,
                            overflow: TextOverflow.ellipsis)),
                    if (_pageCount > 0)
                      Text('$_pageCount pages',
                          style: theme.textTheme.labelSmall),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Split point ─────────────────────────────────────────
            if (_pageCount > 1 && _parts.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Split after page:',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: Slider(
                            value: _splitAfter.toDouble(),
                            min: 1,
                            max: (_pageCount - 1).toDouble(),
                            divisions: _pageCount - 2 > 0
                                ? _pageCount - 2
                                : 1,
                            label: '$_splitAfter',
                            onChanged: (v) =>
                                setState(() => _splitAfter = v.round()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$_splitAfter / $_pageCount',
                            style: theme.textTheme.bodyMedium),
                      ]),
                      Text(
                          'Part 1: pages 1–$_splitAfter  •  '
                          'Part 2: pages ${_splitAfter + 1}–$_pageCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline)),
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
            if (_parts.isNotEmpty) ...[
              for (var i = 0; i < _parts.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Part ${i + 1}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                            '${(_parts[i].length / 1024).toStringAsFixed(0)} KB',
                            style: theme.textTheme.labelSmall),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  icon: const Icon(Icons.download_outlined,
                                      size: 16),
                                  label: const Text('Save'),
                                  onPressed: () => _savePart(i))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton.icon(
                                  icon: const Icon(Icons.share_outlined,
                                      size: 16),
                                  label: const Text('Share'),
                                  onPressed: () => _sharePart(i))),
                        ]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // ── Split button ─────────────────────────────────────────
            if (!_isProcessing && _pageCount > 1 && _parts.isEmpty)
              FilledButton.icon(
                icon: const Icon(Icons.call_split_outlined),
                label: const Text('Split PDF'),
                onPressed: _split,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
