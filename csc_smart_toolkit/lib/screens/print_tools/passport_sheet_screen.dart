import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFF2563EB);

class _PhotoType {
  const _PhotoType(this.name, this.widthMm, this.heightMm, this.perA4);
  final String name;
  final double widthMm, heightMm;
  final int perA4;
  String get dimension => '${widthMm.toInt()}×${heightMm.toInt()} mm';
}

class PassportSheetScreen extends StatefulWidget {
  const PassportSheetScreen({super.key});

  @override
  State<PassportSheetScreen> createState() => _PassportSheetScreenState();
}

class _PassportSheetScreenState extends State<PassportSheetScreen> {
  static const _types = [
    _PhotoType('Passport',  35, 45, 8),
    _PhotoType('Visa',      35, 45, 8),
    _PhotoType('Stamp',     25, 30, 12),
    _PhotoType('Aadhaar',   35, 45, 8),
    _PhotoType('Custom',    40, 50, 6),
  ];

  String? _imagePath;
  _PhotoType _selected = _types[0];
  int _copies = 8;
  double _gapMm = 3.0;
  bool _exporting = false;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _export() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please import a photo first')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final imageBytes = await File(_imagePath!).readAsBytes();
      // Use the selected photo type's actual dimensions so the grid layout
      // correctly sizes each cell (e.g. 35×45 mm passport vs 25×30 mm stamp).
      final pdfBytes = await PrintLayoutService.buildPassportSheet(
        photoBytes: imageBytes,
        copies: _copies,
        itemWidthMm: _selected.widthMm,
        itemHeightMm: _selected.heightMm,
        gapMm: _gapMm,
        marginMm: 8.0,
      );
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/PassportSheet_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], subject: '${_selected.name} Photo Sheet'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'passport-sheet', toolName: 'Passport Sheet', category: 'Print Tools',
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
      appBar: AppBar(title: const Text('Passport Sheet'), backgroundColor: cs.surface),
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
              : Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_imagePath!), width: 90, height: 110, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Photo imported', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${_selected.dimension} · $_copies copies', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: _pickImage,
                          icon: const Icon(Icons.edit, size: 14), label: const Text('Change'),
                          style: OutlinedButton.styleFrom(foregroundColor: _kColor,
                              side: const BorderSide(color: _kColor),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
                    ]),
                  ),
                ]),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'PHOTO TYPE'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: _types.map((t) => ChoiceChip(
              label: Text('${t.name}\n${t.dimension}'),
              selected: _selected.name == t.name,
              onSelected: (_) => setState(() { _selected = t; _copies = t.perA4; }),
              selectedColor: _kColor.withAlpha(40),
              labelStyle: TextStyle(
                  color: _selected.name == t.name ? _kColor : cs.onSurface,
                  fontWeight: _selected.name == t.name ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11),
              side: BorderSide(color: _selected.name == t.name ? _kColor : cs.outline.withAlpha(100)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList()),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'COPIES ON A4: $_copies'),
          Slider(value: _copies.toDouble(), min: 1, max: 20, divisions: 19,
              activeColor: _kColor, onChanged: (v) => setState(() => _copies = v.round())),
          Wrap(spacing: 8, runSpacing: 4,
            children: [4, 6, 8, 12, 16, 20].map((n) => ActionChip(label: Text('$n'),
                onPressed: () => setState(() => _copies = n),
                backgroundColor: _copies == n ? _kColor.withAlpha(40) : null,
                side: BorderSide(color: _copies == n ? _kColor : cs.outline.withAlpha(80)))).toList()),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'SPACING: ${_gapMm.toInt()} mm'),
          Slider(value: _gapMm, min: 0, max: 8, divisions: 8, activeColor: _kColor,
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

  Widget _ebtn(String l, Color c, IconData icon, VoidCallback cb) =>
      ElevatedButton.icon(onPressed: cb, icon: Icon(icon, size: 16), label: Text(l),
          style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
}
