import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/photo_service.dart';

class PDFToImageScreen extends StatefulWidget {
  const PDFToImageScreen({super.key});

  @override
  State<PDFToImageScreen> createState() => _PDFToImageScreenState();
}

class _PDFToImageScreenState extends State<PDFToImageScreen> {
  Uint8List? _pdfBytes;
  String _pdfName = '';
  List<Uint8List> _pages = [];
  bool _isProcessing = false;
  double _progress = 0;
  String _stage = '';
  double _dpi = 150;
  bool _allSaved = false;

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
      _pages = [];
      _allSaved = false;
    });
  }

  Future<void> _convert() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.2;
      _stage = 'Rendering pages at ${_dpi.toInt()} DPI…';
    });
    final pages = await PDFService.pdfToImages(_pdfBytes!, dpi: _dpi);
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _isProcessing = false;
      _progress = 1.0;
      _stage = 'Done';
    });
  }

  Future<void> _saveAll() async {
    if (_pages.isEmpty) return;
    final prefix = _pdfName.replaceAll('.pdf', '');
    for (var i = 0; i < _pages.length; i++) {
      final name = '${prefix}_page${i + 1}_'
          '${DateTime.now().millisecondsSinceEpoch}.png';
      await PhotoService.saveToDocuments(_pages[i], name);
    }
    if (!mounted) return;
    setState(() => _allSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${_pages.length} images')),
    );
    context.read<HistoryProvider>().recordUsage(
        toolId: 'pdf-to-image',
        toolName: 'PDF to Image',
        category: 'PDF Tools');
  }

  Future<void> _sharePage(int index) async {
    final name = PhotoService.timestampFilename('page_${index + 1}', 'png');
    await PhotoService.shareBytes(_pages[index], name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Image'),
        actions: [
          if (_pages.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {
                      _pages = [];
                      _allSaved = false;
                    })),
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

            // ── DPI selector ─────────────────────────────────────────
            if (_pdfBytes != null && _pages.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Output quality',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(
                              value: 72, label: Text('72 DPI')),
                          ButtonSegment(
                              value: 150, label: Text('150 DPI')),
                          ButtonSegment(
                              value: 300, label: Text('300 DPI')),
                        ],
                        selected: {_dpi},
                        onSelectionChanged: (s) =>
                            setState(() => _dpi = s.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 4),
                      Text(
                          _dpi == 72
                              ? 'Small file size'
                              : _dpi == 150
                                  ? 'Balanced'
                                  : 'High quality (large file)',
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

            // ── Pages grid ───────────────────────────────────────────
            if (_pages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_pages.length} pages extracted',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  FilledButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Save All'),
                    onPressed: _allSaved ? null : _saveAll,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _pages.length,
                itemBuilder: (context, i) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.memory(_pages[i], fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Page ${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11)),
                            GestureDetector(
                              onTap: () => _sharePage(i),
                              child: const Icon(Icons.share_outlined,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],

            // ── Convert button ────────────────────────────────────────
            const SizedBox(height: 12),
            if (!_isProcessing && _pdfBytes != null && _pages.isEmpty)
              FilledButton.icon(
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Convert to Images'),
                onPressed: _convert,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
