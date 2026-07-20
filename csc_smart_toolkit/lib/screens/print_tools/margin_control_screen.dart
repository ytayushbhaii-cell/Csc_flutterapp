import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/print_layout_service.dart';

const _kColor = Color(0xFF6366F1);

class MarginControlScreen extends StatefulWidget {
  const MarginControlScreen({super.key});

  @override
  State<MarginControlScreen> createState() => _MarginControlScreenState();
}

class _MarginControlScreenState extends State<MarginControlScreen> {
  String? _imagePath;
  PaperSize _paper = PaperSize.a4;
  double _topMm    = 10.0;
  double _bottomMm = 10.0;
  double _leftMm   = 10.0;
  double _rightMm  = 10.0;
  bool _linked     = true; // link all margins together
  bool _autoCenter = false;
  bool _exporting  = false;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _imagePath = x.path);
  }

  void _setAll(double v) => setState(() {
    _topMm = _bottomMm = _leftMm = _rightMm = v;
  });

  Future<void> _export() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please import an image first')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final imageBytes = await File(_imagePath!).readAsBytes();
      final doc  = pw.Document();
      final img  = pw.MemoryImage(imageBytes);
      const mPt  = PaperSize.mmToPt;

      doc.addPage(pw.Page(
        pageFormat: _paper.pdfFormat,
        margin: pw.EdgeInsets.fromLTRB(
            _leftMm * mPt, _topMm * mPt, _rightMm * mPt, _bottomMm * mPt),
        build: (ctx) => _autoCenter
            ? pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain))
            : pw.Image(img, fit: pw.BoxFit.contain),
      ));

      final pdfBytes = await doc.save();
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/MarginLayout_$ts.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Custom Margin Layout'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'margin-control', toolName: 'Margin Control', category: 'Print Tools',
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
      appBar: AppBar(title: const Text('Margin Control'), backgroundColor: cs.surface),
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
                          width: double.infinity, height: 160, fit: BoxFit.cover)),
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
            children: PaperSize.all.map((p) =>
                _chip(theme, p.name, _paper.name == p.name, () => setState(() => _paper = p))).toList()),
          const SizedBox(height: 16),

          // Link toggle
          Row(children: [
            _lbl(theme, cs, 'MARGINS (mm)'),
            const Spacer(),
            Row(children: [
              Icon(Icons.link, size: 16, color: _linked ? _kColor : cs.onSurface.withAlpha(100)),
              const SizedBox(width: 4),
              Text('Link all', style: theme.textTheme.bodySmall),
              Switch(value: _linked, onChanged: (v) => setState(() => _linked = v), activeColor: _kColor),
            ]),
          ]),
          const SizedBox(height: 8),

          if (_linked)
            _marginSlider(theme, cs, 'All Sides', _topMm, (v) => _setAll(v))
          else ...[
            _marginSlider(theme, cs, 'Top',    _topMm,    (v) => setState(() => _topMm    = v)),
            _marginSlider(theme, cs, 'Bottom', _bottomMm, (v) => setState(() => _bottomMm = v)),
            _marginSlider(theme, cs, 'Left',   _leftMm,   (v) => setState(() => _leftMm   = v)),
            _marginSlider(theme, cs, 'Right',  _rightMm,  (v) => setState(() => _rightMm  = v)),
          ],
          const SizedBox(height: 8),

          SwitchListTile(
            value: _autoCenter, onChanged: (v) => setState(() => _autoCenter = v),
            title: const Text('Auto Center Image'),
            subtitle: const Text('Center content within the margins'),
            activeColor: _kColor, contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          _lbl(theme, cs, 'MARGIN PREVIEW'),
          const SizedBox(height: 8),
          _MarginDiagram(top: _topMm, bottom: _bottomMm, left: _leftMm, right: _rightMm, color: _kColor),
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

  Widget _marginSlider(ThemeData t, ColorScheme cs, String label, double value, ValueChanged<double> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: t.textTheme.bodySmall),
          Text('${value.toInt()} mm', style: t.textTheme.bodySmall?.copyWith(color: _kColor, fontWeight: FontWeight.w600)),
        ]),
        Slider(value: value, min: 0, max: 40, divisions: 40, activeColor: _kColor, onChanged: onChanged),
      ]);

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

class _MarginDiagram extends StatelessWidget {
  const _MarginDiagram({required this.top, required this.bottom, required this.left, required this.right, required this.color});
  final double top, bottom, left, right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
        color: color.withAlpha(10),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Margin borders
        Positioned(top: 4, left: 0, right: 0,
            child: Center(child: Text('T: ${top.toInt()}', style: TextStyle(fontSize: 9, color: color)))),
        Positioned(bottom: 4, left: 0, right: 0,
            child: Center(child: Text('B: ${bottom.toInt()}', style: TextStyle(fontSize: 9, color: color)))),
        Positioned(left: 4, top: 0, bottom: 0,
            child: RotatedBox(quarterTurns: 3,
                child: Text('L: ${left.toInt()}', style: TextStyle(fontSize: 9, color: color)))),
        Positioned(right: 4, top: 0, bottom: 0,
            child: RotatedBox(quarterTurns: 1,
                child: Text('R: ${right.toInt()}', style: TextStyle(fontSize: 9, color: color)))),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            border: Border.all(color: color.withAlpha(100)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.image_outlined, color: color.withAlpha(140), size: 24),
        ),
      ]),
    );
  }
}
