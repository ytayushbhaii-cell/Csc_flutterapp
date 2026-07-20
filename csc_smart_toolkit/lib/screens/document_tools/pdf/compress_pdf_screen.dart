import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class CompressPDFScreen extends StatefulWidget {
  const CompressPDFScreen({super.key});

  @override
  State<CompressPDFScreen> createState() => _CompressPDFScreenState();
}

class _CompressPDFScreenState extends State<CompressPDFScreen> {
  Uint8List? _pdfBytes;
  String _pdfName = '';
  Uint8List? _result;
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  double _quality = 60;

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

  Future<void> _compress() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.3;
      _stage = 'Compressing PDF…';
    });
    final result = await PDFService.compressPdf(_pdfBytes!,
        quality: _quality.round());
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
    final name = PhotoService.timestampFilename('compressed', 'pdf');
    final path = await PhotoService.saveToDocuments(_result!, name);
    if (mounted) {
      PhotoService.showSavedSnackbar(context, path);
      context.read<HistoryProvider>().recordUsage(
          toolId: 'pdf-compress',
          toolName: 'Compress PDF',
          category: 'PDF Tools');
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final name = PhotoService.timestampFilename('compressed', 'pdf');
    await PhotoService.shareBytes(_result!, name);
  }

  String get _qualityLabel {
    if (_quality < 35) return 'Low';
    if (_quality < 70) return 'Medium';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origKb = _pdfBytes != null ? _pdfBytes!.length ~/ 1024 : 0;
    final resultKb = _result != null ? _result!.length ~/ 1024 : 0;
    final saving = _result != null && _pdfBytes != null
        ? (1 - _result!.length / _pdfBytes!.length) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress PDF'),
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
                          if (origKb > 0)
                            Text('$origKb KB',
                                style: theme.textTheme.labelSmall),
                        ])),
                    const Icon(Icons.upload_file_outlined),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quality slider ───────────────────────────────────────
            if (_pdfBytes != null && _result == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Quality:',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(_qualityLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary)),
                      ]),
                      Slider(
                        value: _quality,
                        min: 10,
                        max: 95,
                        divisions: 17,
                        label: '$_quality%',
                        onChanged: (v) => setState(() => _quality = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Smaller',
                              style: theme.textTheme.labelSmall),
                          Text('Better',
                              style: theme.textTheme.labelSmall),
                        ],
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
            if (_result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatChip('Original', '$origKb KB',
                              Colors.orange),
                          const Icon(Icons.arrow_forward,
                              color: Colors.grey),
                          _StatChip('Result', '$resultKb KB', Colors.green),
                          _StatChip('Saved',
                              '${saving.toStringAsFixed(0)}%', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Buttons ───────────────────────────────────────────────
            if (!_isProcessing) ...[
              if (_pdfBytes != null && _result == null)
                FilledButton.icon(
                  icon: const Icon(Icons.compress),
                  label: const Text('Compress PDF'),
                  onPressed: _compress,
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

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}
