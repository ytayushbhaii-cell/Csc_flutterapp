import 'dart:io';
import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/barcode_service.dart';

const _kBarcodeColor = Color(0xFF7C3AED);

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  BarcodeFormat _format = BarcodeFormat.code128;
  final _textCtrl = TextEditingController();
  Color _barColor = Colors.black;
  bool _exporting = false;
  String? _validationError;
  final _repaintKey = GlobalKey();

  static const _colors = [
    Colors.black, Color(0xFF1D4ED8), Color(0xFF7C3AED),
    Color(0xFFDC2626), Color(0xFF059669),
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_validate);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final err = BarcodeService.validate(_textCtrl.text.trim(), _format);
    setState(() => _validationError = err);
  }

  bool get _valid =>
      _textCtrl.text.trim().isNotEmpty && _validationError == null;

  Future<Uint8List> _capture() =>
      BarcodeService.captureWidget(_repaintKey);

  Future<void> _exportPng() async {
    if (!_valid) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Barcode_${_format.label}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Barcode'));
      _recordHistory();
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (!_valid) return;
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capture();
      final pdfBytes = await BarcodeService.pngToPdf(pngBytes,
          label: _textCtrl.text.trim());
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Barcode_${_format.label}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Barcode PDF'));
      _recordHistory();
    } catch (e) {
      _showError('PDF export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() async {
    if (!_valid) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Barcode_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: _textCtrl.text.trim()));
    } catch (e) {
      _showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _recordHistory() {
    context.read<HistoryProvider>().recordUsage(
          toolId: 'barcode-gen',
          toolName: 'Barcode Generator',
          category: 'QR & Barcode',
        );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _textCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Generator'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Format selector ───────────────────────────────────────────────
          Text('FORMAT', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BarcodeFormat.values.map((f) {
                final sel = f == _format;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: sel,
                    onSelected: (_) {
                      setState(() {
                        _format = f;
                        _validationError =
                            BarcodeService.validate(text, f);
                      });
                    },
                    selectedColor: _kBarcodeColor.withAlpha(40),
                    labelStyle: TextStyle(
                      color: sel ? _kBarcodeColor : cs.onSurface,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                        color: sel
                            ? _kBarcodeColor
                            : cs.outline.withAlpha(100)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text(_format.hint,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(120))),
          const SizedBox(height: 16),

          // ── Input ─────────────────────────────────────────────────────────
          TextField(
            controller: _textCtrl,
            decoration: InputDecoration(
              labelText: 'Barcode content',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              errorText: _validationError,
            ),
          ),
          const SizedBox(height: 16),

          // ── Preview ───────────────────────────────────────────────────────
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: _valid
                    ? RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: BarcodeWidget(
                            barcode: _format.barcodeType,
                            data: text,
                            color: _barColor,
                            width: 280,
                            height: 90,
                            drawText: true,
                            style: const TextStyle(fontSize: 11),
                            errorBuilder: (ctx, err) => Text(
                              err,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.barcode_reader,
                              size: 64,
                              color: cs.onSurface.withAlpha(60)),
                          const SizedBox(height: 8),
                          Text('Enter content to generate barcode',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withAlpha(120))),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Bar color ─────────────────────────────────────────────────────
          Text('BAR COLOR', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: _colors.map((c) {
              final sel = _barColor == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _barColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: _kBarcodeColor, width: 2.5)
                          : Border.all(
                              color: cs.outline.withAlpha(60), width: 1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Export ────────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _valid && !_exporting ? _exportPng : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kBarcodeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.download_outlined),
            label: Text(_exporting ? 'Exporting…' : 'Export PNG'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _valid && !_exporting ? _exportPdf : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBarcodeColor,
              side: BorderSide(color: _kBarcodeColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _valid && !_exporting ? _share : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBarcodeColor,
              side: BorderSide(color: _kBarcodeColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
