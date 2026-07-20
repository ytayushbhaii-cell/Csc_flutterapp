import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class MergePDFScreen extends StatefulWidget {
  const MergePDFScreen({super.key});

  @override
  State<MergePDFScreen> createState() => _MergePDFScreenState();
}

class _MergePDFScreenState extends State<MergePDFScreen> {
  final List<_PdfEntry> _files = [];
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';

  Future<void> _addFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;
    final entries = <_PdfEntry>[];
    for (final pf in result.files) {
      if (pf.path != null) {
        final bytes = await File(pf.path!).readAsBytes();
        entries.add(_PdfEntry(pf.name, bytes));
      }
    }
    setState(() {
      _files.addAll(entries);
      _result = null;
    });
  }

  void _remove(int i) => setState(() {
        _files.removeAt(i);
        _result = null;
      });

  void _moveUp(int i) {
    if (i <= 0) return;
    setState(() {
      final tmp = _files[i];
      _files[i] = _files[i - 1];
      _files[i - 1] = tmp;
      _result = null;
    });
  }

  void _moveDown(int i) {
    if (i >= _files.length - 1) return;
    setState(() {
      final tmp = _files[i];
      _files[i] = _files[i + 1];
      _files[i + 1] = tmp;
      _result = null;
    });
  }

  Future<void> _merge() async {
    if (_files.length < 2) return;
    setState(() {
      _isProcessing = true;
      _progress = 0;
      _stage = 'Rendering pages…';
    });
    final bytes = _files.map((e) => e.bytes).toList();
    // Update progress per file
    final allImages = <Uint8List>[];
    for (var i = 0; i < bytes.length; i++) {
      if (!mounted) return;
      setState(() {
        _stage = 'Rendering file ${i + 1}/${bytes.length}…';
        _progress = (i + 1) / bytes.length * 0.8;
      });
      allImages.addAll(await PDFService.pdfToImages(bytes[i], dpi: 150));
    }
    if (!mounted) return;
    setState(() { _stage = 'Building merged PDF…'; _progress = 0.9; });
    final merged = await PDFService.imagesToPdf(allImages);
    if (!mounted) return;
    setState(() {
      _result = merged;
      _isProcessing = false;
      _progress = 1.0;
      _stage = 'Done';
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('merged_pdf', 'pdf');
    final path = await PhotoService.saveToDocuments(_result!, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-merge', toolName: 'Merge PDF', category: 'PDF Tools');
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('merged_pdf', 'pdf');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFDC2626);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDF'),
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
            // ── Add Files ───────────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add PDF Files'),
              onPressed: _isProcessing ? null : _addFiles,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),

            // ── File list ────────────────────────────────────────────
            if (_files.isNotEmpty) ...[
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < _files.length; i++)
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined,
                            color: color),
                        title: Text(_files[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                            '${(_files[i].bytes.length / 1024).toStringAsFixed(0)} KB'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: i > 0 ? () => _moveUp(i) : null),
                          IconButton(
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              onPressed: i < _files.length - 1
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
                    Expanded(
                      child: Text(
                          'Merged PDF ready  •  '
                          '${(_result!.length / 1024).toStringAsFixed(0)} KB',
                          style: theme.textTheme.bodyMedium),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 12),

            // ── Buttons ───────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_result == null && _files.length >= 2)
                FilledButton.icon(
                  icon: const Icon(Icons.call_merge_outlined),
                  label: Text('Merge ${_files.length} Files'),
                  onPressed: _merge,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              if (_result != null) ...[
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Save'),
                      onPressed: _save,
                    ),
                  ),
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
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PdfEntry {
  _PdfEntry(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}
