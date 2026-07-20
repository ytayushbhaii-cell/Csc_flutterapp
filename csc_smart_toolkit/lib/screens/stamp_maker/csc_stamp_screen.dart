import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/stamp_service.dart';

const _kStampColor = Color(0xFFF43F5E);

class CscStampScreen extends StatefulWidget {
  const CscStampScreen({super.key});

  @override
  State<CscStampScreen> createState() => _CscStampScreenState();
}

class _CscStampScreenState extends State<CscStampScreen> {
  final _vleNameCtrl   = TextEditingController(text: 'VLE NAME');
  final _villageCtrl   = TextEditingController(text: 'VILLAGE / PANCHAYAT');
  final _districtCtrl  = TextEditingController(text: 'DISTRICT');
  final _stateCtrl     = TextEditingController(text: 'STATE');
  final _cscIdCtrl     = TextEditingController(text: '');
  Color _inkColor      = const Color(0xFF1A237E);
  bool _exporting      = false;
  final _repaintKey    = GlobalKey();

  @override
  void dispose() {
    _vleNameCtrl.dispose(); _villageCtrl.dispose();
    _districtCtrl.dispose(); _stateCtrl.dispose(); _cscIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _export(bool isPdf) async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await StampService.captureWidget(_repaintKey);
      final dir = await getTemporaryDirectory();
      if (isPdf) {
        final pdfBytes = await StampService.pngToPdf(pngBytes, title: 'CSC Stamp');
        final file = File('${dir.path}/CscStamp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      } else {
        final file = File('${dir.path}/CscStamp_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
            toolId: 'csc-stamp',
            toolName: 'CSC Stamp',
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
      appBar: AppBar(title: const Text('CSC Stamp'), backgroundColor: cs.surface),
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
                  child: _CscStampPreview(
                    vleName: _vleNameCtrl.text,
                    village: _villageCtrl.text,
                    district: _districtCtrl.text,
                    state: _stateCtrl.text,
                    cscId: _cscIdCtrl.text,
                    inkColor: _inkColor,
                    size: 240,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fields ────────────────────────────────────────────────────────
          Text('VLE DETAILS', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...[
            ['VLE Name', _vleNameCtrl],
            ['Village / Panchayat', _villageCtrl],
            ['District', _districtCtrl],
            ['State', _stateCtrl],
            ['CSC ID (optional)', _cscIdCtrl],
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

          // ── Ink color ─────────────────────────────────────────────────────
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
                          color: Color(ic.value), shape: BoxShape.circle,
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
          const SizedBox(height: 20),

          // ── Export ────────────────────────────────────────────────────────
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
          const SizedBox(height: 12),
          Card(
            color: _kStampColor.withAlpha(15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _kStampColor.withAlpha(60))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _kStampColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CSC stamp format follows the Common Service Centre (Digital India) '
                      'guidelines. Fill in your VLE details to personalise.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(160)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── CSC stamp painter ─────────────────────────────────────────────────────────

class _CscStampPreview extends StatelessWidget {
  const _CscStampPreview({
    required this.vleName, required this.village,
    required this.district, required this.state, required this.cscId,
    required this.inkColor, required this.size,
  });
  final String vleName, village, district, state, cscId;
  final Color inkColor;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CscStampPainter(
      vleName: vleName, village: village,
      district: district, state: state, cscId: cscId,
      inkColor: inkColor),
  );
}

class _CscStampPainter extends CustomPainter {
  _CscStampPainter({
    required this.vleName, required this.village,
    required this.district, required this.state, required this.cscId,
    required this.inkColor,
  });
  final String vleName, village, district, state, cscId;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 12;

    canvas.drawCircle(Offset(cx, cy), outerR, Paint()
      ..color = inkColor ..strokeWidth = 4 ..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()
      ..color = inkColor ..strokeWidth = 2 ..style = PaintingStyle.stroke);

    // Top arc: "CSC - DIGITAL SEVA KENDRA"
    _arcText(canvas, 'CSC - DIGITAL SEVA KENDRA', cx, cy,
        outerR - 7, 200 * math.pi / 180, 340 * math.pi / 180, 9, false);

    // Bottom arc: district + state
    final bottomStr = [district, state].where((s) => s.isNotEmpty).join(', ');
    if (bottomStr.isNotEmpty) {
      _arcText(canvas, bottomStr.toUpperCase(), cx, cy,
          outerR - 7, 20 * math.pi / 180, 160 * math.pi / 180, 8, true);
    }

    // Center lines
    final centerLines = <String>[
      if (vleName.isNotEmpty) vleName.toUpperCase(),
      if (village.isNotEmpty) village.toUpperCase(),
      if (cscId.isNotEmpty) 'ID: $cscId',
    ];
    if (centerLines.isEmpty) return;
    final spacing = innerR * 1.6 / (centerLines.length + 1);
    final top = cy - innerR * 0.6;
    for (int i = 0; i < centerLines.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: centerLines[i],
            style: TextStyle(color: inkColor, fontSize: i == 0 ? 11 : 9,
                fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
      )..layout(maxWidth: innerR * 1.6);
      tp.paint(canvas, Offset(cx - tp.width / 2, top + spacing * (i + 1)));
    }
  }

  void _arcText(Canvas canvas, String text, double cx, double cy,
      double radius, double start, double end, double fontSize, bool flip) {
    if (text.isEmpty) return;
    final chars = text.split('');
    final total = end - start;
    final step = total / math.max(chars.length, 1);
    for (int i = 0; i < chars.length; i++) {
      final angle = start + step / 2 + i * step;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(flip ? angle - math.pi / 2 : angle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(text: chars[i],
            style: TextStyle(color: inkColor, fontSize: fontSize,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CscStampPainter o) =>
      o.vleName != vleName || o.village != village ||
      o.district != district || o.state != state ||
      o.cscId != cscId || o.inkColor != inkColor;
}
