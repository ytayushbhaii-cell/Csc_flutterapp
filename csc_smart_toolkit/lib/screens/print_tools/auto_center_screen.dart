import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFFD97706);

class AutoCenterScreen extends StatefulWidget {
  const AutoCenterScreen({super.key});

  @override
  State<AutoCenterScreen> createState() => _AutoCenterScreenState();
}

class _AutoCenterScreenState extends State<AutoCenterScreen> {
  String? _imagePath;
  PaperSize _paper   = PaperSize.a4;
  double _marginMm   = 10.0;
  bool _exporting    = false;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _export() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please import an image first')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final imageBytes = await File(_imagePath!).readAsBytes();
      final pdfBytes = await PrintLayoutService.buildSingleImagePdf(
        imageBytes: imageBytes, paper: _paper,
        marginMm: _marginMm, autoCenter: true, fitToPage: false,
      );
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/AutoCenter_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Auto Center Layout'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'auto-center', toolName: 'Auto Center', category: 'Print Tools',
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
      appBar: AppBar(title: const Text('Auto Center'), backgroundColor: cs.surface),
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
                          width: double.infinity, height: 180, fit: BoxFit.contain)),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(onTap: _pickImage,
                      child: Container(padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16)))),
                ]),
          const SizedBox(height: 16),

          Card(
            color: _kColor.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.filter_center_focus, color: _kColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Auto Center places your image at the exact center of the page with equal margins on all sides.',
                      style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'PAPER SIZE'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: PaperSize.all.map((p) =>
                _chip(theme, p.name, _paper.name == p.name, () => setState(() => _paper = p))).toList()),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'MARGIN: ${_marginMm.toInt()} mm'),
          Slider(value: _marginMm, min: 5, max: 30, divisions: 25, activeColor: _kColor,
              onChanged: (v) => setState(() => _marginMm = v)),
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
