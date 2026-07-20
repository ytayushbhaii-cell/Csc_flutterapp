import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFFDB2777);

class PhotoPaperScreen extends StatefulWidget {
  const PhotoPaperScreen({super.key});

  @override
  State<PhotoPaperScreen> createState() => _PhotoPaperScreenState();
}

class _PhotoPaperScreenState extends State<PhotoPaperScreen> {
  String? _imagePath;
  PaperSize _paper = PaperSize.photo4x6;
  double _marginMm = 4.0;
  bool _autoCenter = true;
  bool _fitToPage  = false;
  bool _exporting  = false;

  static const _photoPapers = [PaperSize.photo4x6, PaperSize.photo5x7];

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
        imageBytes: imageBytes,
        paper: _paper,
        marginMm: _marginMm,
        autoCenter: _autoCenter,
        fitToPage: _fitToPage,
      );
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/PhotoPaper_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: '${_paper.name} Photo Print'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'photo-paper', toolName: 'Photo Paper', category: 'Print Tools',
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
      appBar: AppBar(title: const Text('Photo Paper'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _lbl(theme, cs, 'PHOTO'),
          const SizedBox(height: 8),
          _imagePath == null
              ? OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import Photo'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _kColor, side: const BorderSide(color: _kColor),
                      padding: const EdgeInsets.symmetric(vertical: 14)))
              : Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_imagePath!),
                          width: double.infinity, height: 200, fit: BoxFit.cover)),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(onTap: _pickImage,
                      child: Container(padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16)))),
                ]),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'PAPER SIZE'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: _photoPapers.map((p) => ChoiceChip(
              label: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text('${p.widthMm.toInt()}×${p.heightMm.toInt()} mm',
                    style: const TextStyle(fontSize: 10)),
              ]),
              selected: _paper.name == p.name,
              onSelected: (_) => setState(() => _paper = p),
              selectedColor: _kColor.withAlpha(40),
              labelStyle: TextStyle(color: _paper.name == p.name ? _kColor : cs.onSurface),
              side: BorderSide(color: _paper.name == p.name ? _kColor : cs.outline.withAlpha(100)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            )).toList()),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'BORDER / MARGIN: ${_marginMm.toStringAsFixed(1)} mm'),
          Slider(value: _marginMm, min: 0, max: 10, divisions: 20, activeColor: _kColor,
              onChanged: (v) => setState(() => _marginMm = v)),
          const SizedBox(height: 8),

          SwitchListTile(
            value: _autoCenter, onChanged: (v) => setState(() { _autoCenter = v; if (v) _fitToPage = false; }),
            title: const Text('Auto Center'), activeColor: _kColor, contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _fitToPage, onChanged: (v) => setState(() { _fitToPage = v; if (v) _autoCenter = false; }),
            title: const Text('Fit to Paper'), activeColor: _kColor, contentPadding: EdgeInsets.zero,
          ),
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

  Widget _ebtn(String l, Color c, IconData icon, VoidCallback cb) =>
      ElevatedButton.icon(onPressed: cb, icon: Icon(icon, size: 16), label: Text(l),
          style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
}
