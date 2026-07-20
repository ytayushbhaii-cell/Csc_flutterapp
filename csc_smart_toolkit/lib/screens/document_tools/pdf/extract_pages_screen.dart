import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

/// Handles both "Extract Pages" and "Delete Pages" modes.
class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({
    super.key,
    this.deleteMode = false,
  });

  /// When true, the selected pages are DELETED; when false they are KEPT.
  final bool deleteMode;

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  Uint8List? _pdfBytes;
  String _pdfName = '';
  int _pageCount = 0;
  final _controller = TextEditingController(text: '1');
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      _stage = 'Counting pages…';
      _result = null;
    });
    final bytes = await File(pf.path!).readAsBytes();
    final count = await PDFService.getPageCount(bytes);
    if (!mounted) return;
    setState(() {
      _pdfBytes = bytes;
      _pdfName = pf.name;
      _pageCount = count;
      _isProcessing = false;
      _stage = '';
    });
  }

  List<int>? _parsePages(String input) {
    final pages = <int>{};
    for (final part in input.split(',')) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length != 2) return null;
        final from = int.tryParse(bounds[0].trim());
        final to = int.tryParse(bounds[1].trim());
        if (from == null || to == null || from > to) return null;
        for (var i = from; i <= to; i++) {
          pages.add(i);
        }
      } else {
        final n = int.tryParse(trimmed);
        if (n == null) return null;
        pages.add(n);
      }
    }
    return pages.toList()..sort();
  }

  Future<void> _process() async {
    if (_pdfBytes == null) return;
    final pages = _parsePages(_controller.text);
    if (pages == null || pages.isEmpty) {
      setState(() => _error = 'Invalid page range. Use format: 1,3,5-7');
      return;
    }
    setState(() {
      _error = null;
      _isProcessing = true;
      _progress = 0.3;
      _stage = widget.deleteMode
          ? 'Deleting selected pages…'
          : 'Extracting selected pages…';
    });
    Uint8List result;
    if (widget.deleteMode) {
      result = await PDFService.deletePages(_pdfBytes!, pages);
    } else {
      result = await PDFService.extractPages(_pdfBytes!, pages);
    }
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
    final prefix = widget.deleteMode ? 'deleted_pages' : 'extracted_pages';
    final name = PhotoService.timestampFilename(prefix, 'pdf');
    final path = await PhotoService.saveToDocuments(_result!, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: widget.deleteMode ? 'pdf-delete' : 'pdf-extract',
          toolName:
              widget.deleteMode ? 'Delete Pages' : 'Extract Pages',
          category: 'PDF Tools');
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final prefix = widget.deleteMode ? 'deleted_pages' : 'extracted_pages';
    final name = PhotoService.timestampFilename(prefix, 'pdf');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        widget.deleteMode ? 'Delete Pages' : 'Extract Pages';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_pdfName.isEmpty
                              ? 'Tap to pick PDF'
                              : _pdfName, overflow: TextOverflow.ellipsis),
                          if (_pageCount > 0)
                            Text('$_pageCount pages',
                                style: theme.textTheme.labelSmall),
                        ])),
                    const Icon(Icons.upload_file_outlined),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Page range input ─────────────────────────────────────
            if (_pdfBytes != null && _result == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.deleteMode
                              ? 'Pages to delete:'
                              : 'Pages to extract:',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'e.g. 1,3,5-7',
                          border: const OutlineInputBorder(),
                          errorText: _error,
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Use commas and ranges: 1,3,5-7  '
                          '(total pages: $_pageCount)',
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

            // ── Result info ───────────────────────────────────────────
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                        'PDF ready  •  '
                        '${(_result!.length / 1024).toStringAsFixed(0)} KB',
                        style: theme.textTheme.bodyMedium),
                  ]),
                ),
              ),
            const SizedBox(height: 12),

            // ── Buttons ───────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_pdfBytes != null && _result == null)
                FilledButton.icon(
                  icon: Icon(widget.deleteMode
                      ? Icons.delete_outline
                      : Icons.content_cut_outlined),
                  label: Text(title),
                  onPressed: _process,
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
