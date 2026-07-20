import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class RotatePDFScreen extends StatefulWidget {
  const RotatePDFScreen({super.key});

  @override
  State<RotatePDFScreen> createState() => _RotatePDFScreenState();
}

class _RotatePDFScreenState extends State<RotatePDFScreen> {
  Uint8List? _pdfBytes;
  String _pdfName = '';
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  int _degrees = 90;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.first;
    if (pf.path == null) return;
    final bytes = await File(pf.path!).readAsBytes();
    setState(() {
      _pdfBytes = bytes;
      _pdfName = pf.name;
      _result = null;
    });
  }

  Future<void> _rotate() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.3;
      _stage = 'Rotating all pages…';
    });
    final result = await PDFService.rotatePdf(_pdfBytes!, _degrees);
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
    final name = PhotoService.timestampFilename('rotated', 'pdf');
    final path = await PhotoService.saveToDocuments(_result!, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-rotate',
          toolName: 'Rotate PDF',
          category: 'PDF Tools');
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('rotated', 'pdf');
    await PhotoService.shareBytes(_result!, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotate PDF'),
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
                        child: Text(
                            _pdfName.isEmpty ? 'Tap to pick PDF' : _pdfName,
                            overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.upload_file_outlined),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Rotation selector ───────────────────────────────────
            if (_pdfBytes != null && _result == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rotation angle',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 90, label: Text('90°')),
                          ButtonSegment(value: 180, label: Text('180°')),
                          ButtonSegment(value: 270, label: Text('270°')),
                        ],
                        selected: {_degrees},
                        onSelectionChanged: (s) =>
                            setState(() => _degrees = s.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 8),
                      Text('Applied to all pages',
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
                        'Rotated PDF ready  •  '
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
                  icon: const Icon(Icons.rotate_right_outlined),
                  label: Text('Rotate $_degrees°'),
                  onPressed: _rotate,
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
