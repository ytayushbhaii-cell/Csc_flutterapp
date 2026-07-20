import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/stamp_service.dart';

const _kStampColor = Color(0xFFF43F5E);

class RoundStampScreen extends StatefulWidget {
  const RoundStampScreen({super.key});

  @override
  State<RoundStampScreen> createState() => _RoundStampScreenState();
}

class _RoundStampScreenState extends State<RoundStampScreen> {
  final _topTextCtrl    = TextEditingController(text: 'COMPANY NAME PVT LTD');
  final _centerCtrl     = TextEditingController(text: 'AUTHORIZED');
  final _bottomTextCtrl = TextEditingController(text: 'REG. NO: 000000');
  Color _inkColor       = const Color(0xFF1A237E);
  int _borderThickness  = 4;
  bool _exporting       = false;
  final _repaintKey     = GlobalKey();

  @override
  void dispose() {
    _topTextCtrl.dispose();
    _centerCtrl.dispose();
    _bottomTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _export(bool isPdf) async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await StampService.captureWidget(_repaintKey);
      final dir = await getTemporaryDirectory();
      if (isPdf) {
        final pdfBytes = await StampService.pngToPdf(pngBytes, title: 'Round Stamp');
        final file = File('${dir.path}/RoundStamp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      } else {
        final file = File('${dir.path}/RoundStamp_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
            toolId: 'round-stamp',
            toolName: 'Round Stamp',
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
      appBar: AppBar(title: const Text('Round Stamp'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Preview ───────────────────────────────────────────────────────
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _RoundStampPreview(
                    topText: _topTextCtrl.text,
                    centerText: _centerCtrl.text,
                    bottomText: _bottomTextCtrl.text,
                    inkColor: _inkColor,
                    borderThickness: _borderThickness.toDouble(),
                    size: 240,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fields ────────────────────────────────────────────────────────
          ..._buildFields(theme, cs),

          // ── Ink color ─────────────────────────────────────────────────────
          ..._buildInkColorPicker(theme, cs),

          // ── Border thickness ──────────────────────────────────────────────
          ..._buildThickness(theme, cs),

          // ── Export ────────────────────────────────────────────────────────
          ..._buildExportButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildFields(ThemeData theme, ColorScheme cs) => [
    Text('STAMP CONTENT', style: theme.textTheme.labelSmall?.copyWith(
        color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
    const SizedBox(height: 8),
    _field(_topTextCtrl, 'Top Text (Arc)', theme),
    const SizedBox(height: 8),
    _field(_centerCtrl, 'Center Text', theme),
    const SizedBox(height: 8),
    _field(_bottomTextCtrl, 'Bottom Text (Arc)', theme),
    const SizedBox(height: 16),
  ];

  Widget _field(TextEditingController ctrl, String label, ThemeData theme) =>
      TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  List<Widget> _buildInkColorPicker(ThemeData theme, ColorScheme cs) => [
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
              child: Row(
                children: [
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
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ),
    const SizedBox(height: 16),
  ];

  List<Widget> _buildThickness(ThemeData theme, ColorScheme cs) => [
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
  ];

  List<Widget> _buildExportButtons() => [
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
  ];
}

// ── Round stamp painter ────────────────────────────────────────────────────────

class _RoundStampPreview extends StatelessWidget {
  const _RoundStampPreview({
    required this.topText,
    required this.centerText,
    required this.bottomText,
    required this.inkColor,
    required this.borderThickness,
    required this.size,
  });
  final String topText, centerText, bottomText;
  final Color inkColor;
  final double borderThickness, size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundStampPainter(
        topText: topText,
        centerText: centerText,
        bottomText: bottomText,
        inkColor: inkColor,
        borderThickness: borderThickness,
      ),
    );
  }
}

class _RoundStampPainter extends CustomPainter {
  _RoundStampPainter({
    required this.topText,
    required this.centerText,
    required this.bottomText,
    required this.inkColor,
    required this.borderThickness,
  });
  final String topText, centerText, bottomText;
  final Color inkColor;
  final double borderThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final outerR = size.width / 2 - 4;
    final innerR = outerR - borderThickness - 6;

    final circlePaint = Paint()
      ..color = inkColor
      ..strokeWidth = borderThickness
      ..style = PaintingStyle.stroke;
    final innerPaint = Paint()
      ..color = inkColor
      ..strokeWidth = borderThickness * 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), outerR, circlePaint);
    canvas.drawCircle(Offset(cx, cy), innerR, innerPaint);

    // Top arc text (200° to 340°)
    _drawArcText(
        canvas, topText, cx, cy, outerR - borderThickness - 3,
        200 * math.pi / 180, 340 * math.pi / 180, 9, false);

    // Bottom arc text (200° to 340° flipped)
    _drawArcText(
        canvas, bottomText, cx, cy, outerR - borderThickness - 3,
        20 * math.pi / 180, 160 * math.pi / 180, 9, true);

    // Center text
    if (centerText.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: centerText.toUpperCase(),
          style: TextStyle(color: inkColor, fontSize: 12,
              fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: innerR * 1.6);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  void _drawArcText(Canvas canvas, String text, double cx, double cy,
      double radius, double startAngle, double endAngle, double fontSize,
      bool flip) {
    if (text.isEmpty) return;
    final chars = text.toUpperCase().split('');
    final totalAngle = endAngle - startAngle;
    final step = totalAngle / math.max(chars.length, 1);
    final offset = step / 2;

    for (int i = 0; i < chars.length; i++) {
      final angle = startAngle + offset + i * step;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      final rotate = flip ? angle - math.pi / 2 : angle + math.pi / 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotate);

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
              color: inkColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoundStampPainter old) =>
      old.topText != topText || old.centerText != centerText ||
      old.bottomText != bottomText || old.inkColor != inkColor ||
      old.borderThickness != borderThickness;
}
