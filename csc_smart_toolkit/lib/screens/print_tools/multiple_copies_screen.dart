import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFF059669);

class MultipleCopiesScreen extends StatefulWidget {
  const MultipleCopiesScreen({super.key});

  @override
  State<MultipleCopiesScreen> createState() => _MultipleCopiesScreenState();
}

class _MultipleCopiesScreenState extends State<MultipleCopiesScreen> {
  String? _imagePath;
  PaperSize _paper    = PaperSize.a4;
  int _copies         = 4;
  double _marginMm    = 10.0;
  double _gapMm       = 5.0;
  bool _exporting     = false;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _export() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please import an image first')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final imageBytes = await File(_imagePath!).readAsBytes();
      final pdfBytes = await PrintLayoutService.buildMultiCopyPdf(
        imageBytes: imageBytes, paper: _paper,
        copies: _copies, marginMm: _marginMm, gapMm: _gapMm,
      );
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/Copies_${_copies}_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: '$_copies Copies'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'multiple-copies', toolName: 'Multiple Copies', category: 'Print Tools',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    // Preview grid calculation
    final layout = PrintLayoutService.calculateGrid(
      paper: _paper, itemWidthMm: 85.6, itemHeightMm: 53.98,
      copies: _copies, marginMm: _marginMm, gapMm: _gapMm,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Multiple Copies'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _lbl(theme, cs, 'IMAGE'),
          const SizedBox(height: 8),
          _imagePath == null
              ? OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import Image'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _kColor, side: const BorderSide(color: _kColor),
                      padding: const EdgeInsets.symmetric(vertical: 14)))
              : Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_imagePath!),
                          width: double.infinity, height: 150, fit: BoxFit.cover)),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(onTap: _pickImage,
                      child: Container(padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16)))),
                ]),
          const SizedBox(height: 16),

          // Layout info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.grid_view_outlined, color: _kColor, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Layout: ${layout.cols} × ${layout.rows}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Fits ${layout.capacity} copies on ${_paper.name}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(140))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Paper size
          _lbl(theme, cs, 'PAPER SIZE'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: [PaperSize.a4, PaperSize.legal, PaperSize.letter].map((p) =>
                _chip(theme, p.name, _paper.name == p.name, () => setState(() => _paper = p))).toList()),
          const SizedBox(height: 16),

          // Copies
          _lbl(theme, cs, 'NUMBER OF COPIES: $_copies'),
          Slider(
            value: _copies.toDouble(), min: 1, max: 50, divisions: 49,
            activeColor: _kColor,
            onChanged: (v) => setState(() => _copies = v.round()),
          ),
          Wrap(spacing: 8, runSpacing: 4,
            children: [1, 2, 4, 6, 8, 12, 16, 20].map((n) =>
                ActionChip(label: Text('$n'), onPressed: () => setState(() => _copies = n),
                    backgroundColor: _copies == n ? _kColor.withAlpha(40) : null,
                    side: BorderSide(color: _copies == n ? _kColor : cs.outline.withAlpha(80)))).toList()),
          const SizedBox(height: 16),

          // Margin
          _lbl(theme, cs, 'MARGIN: ${_marginMm.toInt()} mm'),
          Slider(value: _marginMm, min: 5, max: 20, divisions: 15, activeColor: _kColor,
              onChanged: (v) => setState(() => _marginMm = v)),
          const SizedBox(height: 8),

          // Gap
          _lbl(theme, cs, 'GAP BETWEEN COPIES: ${_gapMm.toInt()} mm'),
          Slider(value: _gapMm, min: 0, max: 10, divisions: 10, activeColor: _kColor,
              onChanged: (v) => setState(() => _gapMm = v)),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'EXPORT'),
          const SizedBox(height: 8),
          _exporting
              ? const Center(child: CircularProgressIndicator())
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  _ebtn('Generate PDF', const Color(0xFFDC2626), Icons.picture_as_pdf_outlined, _export),
                  _ebtn('Share', const Color(0xFF6366F1), Icons.share_outlined, _export),
                ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _lbl(ThemeData t, ColorScheme cs, String s) => Text(s,
      style: t.textTheme.labelSmall?.copyWith(color: cs.onSurface.withAlpha(160), letterSpacing: 0.8));

  Widget _chip(ThemeData t, String label, bool selected, VoidCallback onTap) {
    final cs = t.colorScheme;
    return ChoiceChip(
      label: Text(label), selected: selected, onSelected: (_) => onTap(),
      selectedColor: _kColor.withAlpha(40),
      labelStyle: TextStyle(color: selected ? _kColor : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      side: BorderSide(color: selected ? _kColor : cs.outline.withAlpha(100)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _ebtn(String l, Color c, IconData icon, VoidCallback cb) =>
      ElevatedButton.icon(onPressed: cb, icon: Icon(icon, size: 16), label: Text(l),
          style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
}
