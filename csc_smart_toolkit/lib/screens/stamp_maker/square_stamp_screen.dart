import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/stamp_service.dart';

const _kStampColor = Color(0xFFF43F5E);

class SquareStampScreen extends StatefulWidget {
  const SquareStampScreen({super.key});

  @override
  State<SquareStampScreen> createState() => _SquareStampScreenState();
}

class _SquareStampScreenState extends State<SquareStampScreen> {
  final _line1Ctrl = TextEditingController(text: 'COMPANY NAME PVT LTD');
  final _line2Ctrl = TextEditingController(text: 'AUTHORIZED SIGNATORY');
  final _line3Ctrl = TextEditingController(text: 'REG. NO: 000000');
  final _line4Ctrl = TextEditingController(text: '');
  Color _inkColor      = const Color(0xFF1A237E);
  int _borderThickness = 4;
  bool _exporting      = false;
  final _repaintKey    = GlobalKey();

  @override
  void dispose() {
    _line1Ctrl.dispose(); _line2Ctrl.dispose();
    _line3Ctrl.dispose(); _line4Ctrl.dispose();
    super.dispose();
  }

  Future<void> _export(bool isPdf) async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await StampService.captureWidget(_repaintKey);
      final dir = await getTemporaryDirectory();
      if (isPdf) {
        final pdfBytes = await StampService.pngToPdf(pngBytes, title: 'Square Stamp');
        final file = File('${dir.path}/SquareStamp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      } else {
        final file = File('${dir.path}/SquareStamp_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
            toolId: 'square-stamp',
            toolName: 'Square Stamp',
            category: 'Stamp Maker',
          );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Square Stamp'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _SquareStampPreview(
                    lines: [_line1Ctrl.text, _line2Ctrl.text,
                            _line3Ctrl.text, _line4Ctrl.text],
                    inkColor: _inkColor,
                    borderThickness: _borderThickness.toDouble(),
                    size: 240,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('STAMP LINES', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...[ ['Line 1 (Top)', _line1Ctrl],
               ['Line 2', _line2Ctrl],
               ['Line 3', _line3Ctrl],
               ['Line 4 (Optional)', _line4Ctrl],
          ].map<Widget>((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: e[1] as TextEditingController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: e[0] as String,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          )),
          const SizedBox(height: 8),

          Text('INK COLOR', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InkColor.presets.map((ic) {
                final sel = _inkColor == Color(ic.value);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _inkColor = Color(ic.value)),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Color(ic.value),
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: _kStampColor, width: 2.5)
                              : Border.all(color: cs.outline.withAlpha(60)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(ic.label, style: theme.textTheme.labelSmall),
                      const SizedBox(width: 8),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Text('BORDER THICKNESS', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [2, 3, 4, 5, 6].map((t) {
              final sel = _borderThickness == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _borderThickness = t),
                  child: Container(
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: sel ? _kStampColor : cs.outline.withAlpha(100),
                          width: sel ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                      color: sel ? _kStampColor.withAlpha(20) : null,
                    ),
                    child: Text('$t',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: sel ? _kStampColor : cs.onSurface)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: !_exporting ? () => _export(false) : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kStampColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.download_outlined),
            label: Text(_exporting ? 'Exporting…' : 'Export PNG'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !_exporting ? () => _export(true) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kStampColor,
              side: BorderSide(color: _kStampColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SquareStampPreview extends StatelessWidget {
  const _SquareStampPreview({
    required this.lines,
    required this.inkColor,
    required this.borderThickness,
    required this.size,
  });
  final List<String> lines;
  final Color inkColor;
  final double borderThickness, size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SquareStampPainter(
          lines: lines, inkColor: inkColor, borderThickness: borderThickness),
    );
  }
}

class _SquareStampPainter extends CustomPainter {
  _SquareStampPainter({
    required this.lines,
    required this.inkColor,
    required this.borderThickness,
  });
  final List<String> lines;
  final Color inkColor;
  final double borderThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..strokeWidth = borderThickness
      ..style = PaintingStyle.stroke;
    final innerPaint = Paint()
      ..color = inkColor
      ..strokeWidth = borderThickness * 0.5
      ..style = PaintingStyle.stroke;

    const margin = 6.0;
    final rect = Rect.fromLTWH(margin, margin,
        size.width - margin * 2, size.height - margin * 2);
    final innerRect = Rect.fromLTWH(
        margin + borderThickness + 4,
        margin + borderThickness + 4,
        size.width - (margin + borderThickness + 4) * 2,
        size.height - (margin + borderThickness + 4) * 2);

    canvas.drawRect(rect, paint);
    canvas.drawRect(innerRect, innerPaint);

    // Draw lines vertically centered
    final activeLines = lines.where((l) => l.isNotEmpty).toList();
    if (activeLines.isEmpty) return;

    final lineSpacing = innerRect.height / (activeLines.length + 1);
    for (int i = 0; i < activeLines.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: activeLines[i].toUpperCase(),
          style: TextStyle(
              color: inkColor,
              fontSize: i == 0 ? 11 : 9,
              fontWeight: i == 0 ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.5),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: innerRect.width - 12);

      final y = innerRect.top + lineSpacing * (i + 1) - tp.height / 2;
      tp.paint(canvas,
          Offset(innerRect.center.dx - tp.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(covariant _SquareStampPainter old) =>
      old.lines != lines || old.inkColor != inkColor ||
      old.borderThickness != borderThickness;
}
