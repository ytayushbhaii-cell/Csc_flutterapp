import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFF7C3AED);

class A4LayoutScreen extends StatefulWidget {
  const A4LayoutScreen({super.key});

  @override
  State<A4LayoutScreen> createState() => _A4LayoutScreenState();
}

class _A4LayoutScreenState extends State<A4LayoutScreen> {
  String? _imagePath;
  double _marginMm = 10.0;
  bool _autoCenter = true;
  bool _fitToPage  = false;
  bool _landscape  = false;
  bool _exporting  = false;

  static const _margins = [5.0, 10.0, 15.0, 20.0];

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _export(String format) async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please import an image first')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final imageBytes = await File(_imagePath!).readAsBytes();
      var paper = PaperSize.a4;
      if (_landscape) {
        paper = PaperSize('A4 Landscape', PaperSize.a4.heightMm, PaperSize.a4.widthMm);
      }
      final pdfBytes = await PrintLayoutService.buildSingleImagePdf(
        imageBytes: imageBytes,
        paper: paper,
        marginMm: _marginMm,
        autoCenter: _autoCenter,
        fitToPage: _fitToPage,
      );
      final dir = await getTemporaryDirectory();
      final ts  = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/A4Layout_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'A4 Layout'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'a4-layout', toolName: 'A4 Layout', category: 'Print Tools',
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

    return Scaffold(
      appBar: AppBar(title: const Text('A4 Layout'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Import ────────────────────────────────────────────────────────
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_imagePath!),
                        width: double.infinity, height: 180, fit: BoxFit.cover),
                  ),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ]),
          const SizedBox(height: 16),

          // ── Paper info ────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.article_outlined, color: _kColor, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('A4 Paper', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${_landscape ? "297 × 210" : "210 × 297"} mm  •  ${_landscape ? "Landscape" : "Portrait"}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(140))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Orientation ───────────────────────────────────────────────────
          _lbl(theme, cs, 'ORIENTATION'),
          const SizedBox(height: 8),
          Row(children: [
            _chip(theme, 'Portrait',  !_landscape, () => setState(() => _landscape = false)),
            const SizedBox(width: 8),
            _chip(theme, 'Landscape', _landscape,  () => setState(() => _landscape = true)),
          ]),
          const SizedBox(height: 16),

          // ── Margin ────────────────────────────────────────────────────────
          _lbl(theme, cs, 'MARGIN'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: _margins.map((m) => _chip(theme, '${m.toInt()} mm', _marginMm == m,
                () => setState(() => _marginMm = m))).toList()),
          const SizedBox(height: 16),

          // ── Options ───────────────────────────────────────────────────────
          _lbl(theme, cs, 'OPTIONS'),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _autoCenter, onChanged: (v) => setState(() { _autoCenter = v; if (v) _fitToPage = false; }),
            title: const Text('Auto Center'), subtitle: const Text('Center image on page'),
            activeColor: _kColor, contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _fitToPage, onChanged: (v) => setState(() { _fitToPage = v; if (v) _autoCenter = false; }),
            title: const Text('Fit to Page'), subtitle: const Text('Scale image to fill page'),
            activeColor: _kColor, contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // ── Export ────────────────────────────────────────────────────────
          _lbl(theme, cs, 'EXPORT'),
          const SizedBox(height: 8),
          _exporting
              ? const Center(child: CircularProgressIndicator())
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  _ebtn('PDF',   const Color(0xFFDC2626), Icons.picture_as_pdf_outlined, () => _export('pdf')),
                  _ebtn('Share', const Color(0xFF6366F1), Icons.share_outlined,           () => _export('pdf')),
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
