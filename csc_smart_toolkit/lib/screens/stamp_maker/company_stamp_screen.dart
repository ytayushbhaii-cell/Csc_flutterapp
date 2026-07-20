import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/stamp_service.dart';

const _kStampColor = Color(0xFFF43F5E);

class CompanyStampScreen extends StatefulWidget {
  const CompanyStampScreen({super.key});

  @override
  State<CompanyStampScreen> createState() => _CompanyStampScreenState();
}

class _CompanyStampScreenState extends State<CompanyStampScreen> {
  final _companyCtrl     = TextEditingController(text: 'COMPANY NAME PVT LTD');
  final _designationCtrl = TextEditingController(text: 'AUTHORIZED SIGNATORY');
  final _regNoCtrl       = TextEditingController(text: '');
  final _phoneCtrl       = TextEditingController(text: '');
  final _websiteCtrl     = TextEditingController(text: '');
  Color _inkColor        = const Color(0xFF1A237E);
  StampShape _shape      = StampShape.round;
  int _borderThickness   = 4;
  bool _exporting        = false;
  final _repaintKey      = GlobalKey();

  @override
  void dispose() {
    _companyCtrl.dispose(); _designationCtrl.dispose();
    _regNoCtrl.dispose(); _phoneCtrl.dispose(); _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _export(bool isPdf) async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await StampService.captureWidget(_repaintKey);
      final dir = await getTemporaryDirectory();
      if (isPdf) {
        final pdfBytes = await StampService.pngToPdf(pngBytes, title: 'Company Stamp');
        final file = File('${dir.path}/CompanyStamp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      } else {
        final file = File('${dir.path}/CompanyStamp_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
            toolId: 'company-stamp',
            toolName: 'Company Stamp',
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
      appBar: AppBar(title: const Text('Company Stamp'), backgroundColor: cs.surface),
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
                  child: _shape == StampShape.round
                      ? _CompanyRoundPreview(
                          companyName: _companyCtrl.text,
                          designation: _designationCtrl.text,
                          regNo: _regNoCtrl.text,
                          phone: _phoneCtrl.text,
                          inkColor: _inkColor,
                          borderThickness: _borderThickness.toDouble(),
                          size: 240,
                        )
                      : _CompanySquarePreview(
                          companyName: _companyCtrl.text,
                          designation: _designationCtrl.text,
                          regNo: _regNoCtrl.text,
                          phone: _phoneCtrl.text,
                          website: _websiteCtrl.text,
                          inkColor: _inkColor,
                          borderThickness: _borderThickness.toDouble(),
                          size: 240,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Shape ─────────────────────────────────────────────────────────
          Text('SHAPE', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: StampShape.values.map((s) {
              final sel = _shape == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s.label),
                  selected: sel,
                  onSelected: (_) => setState(() => _shape = s),
                  selectedColor: _kStampColor.withAlpha(40),
                  labelStyle: TextStyle(
                      color: sel ? _kStampColor : cs.onSurface,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                  side: BorderSide(
                      color: sel ? _kStampColor : cs.outline.withAlpha(100)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Fields ────────────────────────────────────────────────────────
          Text('COMPANY DETAILS', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...[
            ['Company Name', _companyCtrl],
            ['Designation', _designationCtrl],
            ['Reg. No (optional)', _regNoCtrl],
            ['Phone (optional)', _phoneCtrl],
            ['Website (optional)', _websiteCtrl],
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
          const SizedBox(height: 16),

          // ── Border thickness ──────────────────────────────────────────────
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _CompanyRoundPreview extends StatelessWidget {
  const _CompanyRoundPreview({
    required this.companyName, required this.designation,
    required this.regNo, required this.phone,
    required this.inkColor, required this.borderThickness, required this.size,
  });
  final String companyName, designation, regNo, phone;
  final Color inkColor;
  final double borderThickness, size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CompanyRoundPainter(
      companyName: companyName, designation: designation,
      regNo: regNo, phone: phone,
      inkColor: inkColor, borderThickness: borderThickness),
  );
}

class _CompanyRoundPainter extends CustomPainter {
  _CompanyRoundPainter({
    required this.companyName, required this.designation,
    required this.regNo, required this.phone,
    required this.inkColor, required this.borderThickness,
  });
  final String companyName, designation, regNo, phone;
  final Color inkColor;
  final double borderThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final outerR = size.width / 2 - 4;
    final innerR = outerR - borderThickness - 6;

    canvas.drawCircle(Offset(cx, cy), outerR, Paint()
      ..color = inkColor ..strokeWidth = borderThickness ..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()
      ..color = inkColor ..strokeWidth = borderThickness * 0.5 ..style = PaintingStyle.stroke);

    _arcText(canvas, companyName.toUpperCase(), cx, cy,
        outerR - borderThickness - 3, 200 * math.pi / 180, 340 * math.pi / 180, 9, false);

    if (regNo.isNotEmpty || phone.isNotEmpty) {
      final sub = [regNo, phone].where((s) => s.isNotEmpty).join(' | ');
      _arcText(canvas, sub.toUpperCase(), cx, cy,
          outerR - borderThickness - 3, 20 * math.pi / 180, 160 * math.pi / 180, 8, true);
    }

    if (designation.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: designation.toUpperCase(),
            style: TextStyle(color: inkColor, fontSize: 11,
                fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
      )..layout(maxWidth: innerR * 1.6);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
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
  bool shouldRepaint(covariant _CompanyRoundPainter o) =>
      o.companyName != companyName || o.designation != designation ||
      o.regNo != regNo || o.phone != phone ||
      o.inkColor != inkColor || o.borderThickness != borderThickness;
}

class _CompanySquarePreview extends StatelessWidget {
  const _CompanySquarePreview({
    required this.companyName, required this.designation,
    required this.regNo, required this.phone, required this.website,
    required this.inkColor, required this.borderThickness, required this.size,
  });
  final String companyName, designation, regNo, phone, website;
  final Color inkColor;
  final double borderThickness, size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CompanySquarePainter(
      lines: [
        companyName,
        designation,
        if (regNo.isNotEmpty) 'Reg: $regNo',
        if (phone.isNotEmpty) phone,
        if (website.isNotEmpty) website,
      ],
      inkColor: inkColor, borderThickness: borderThickness,
    ),
  );
}

class _CompanySquarePainter extends CustomPainter {
  _CompanySquarePainter({required this.lines, required this.inkColor,
      required this.borderThickness});
  final List<String> lines;
  final Color inkColor;
  final double borderThickness;

  @override
  void paint(Canvas canvas, Size size) {
    const m = 6.0;
    final rect = Rect.fromLTWH(m, m, size.width - m*2, size.height - m*2);
    final inner = Rect.fromLTWH(m + borderThickness + 4, m + borderThickness + 4,
        size.width - (m + borderThickness + 4)*2, size.height - (m + borderThickness + 4)*2);
    canvas.drawRect(rect, Paint()..color=inkColor..strokeWidth=borderThickness..style=PaintingStyle.stroke);
    canvas.drawRect(inner, Paint()..color=inkColor..strokeWidth=borderThickness*0.5..style=PaintingStyle.stroke);

    final active = lines.where((l) => l.isNotEmpty).toList();
    if (active.isEmpty) return;
    final spacing = inner.height / (active.length + 1);
    for (int i = 0; i < active.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: active[i].toUpperCase(),
            style: TextStyle(color: inkColor, fontSize: i == 0 ? 11 : 9,
                fontWeight: i == 0 ? FontWeight.bold : FontWeight.w600, letterSpacing: 0.5)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: inner.width - 12);
      tp.paint(canvas, Offset(inner.center.dx - tp.width/2,
          inner.top + spacing*(i+1) - tp.height/2));
    }
  }

  @override
  bool shouldRepaint(covariant _CompanySquarePainter o) =>
      o.lines != lines || o.inkColor != inkColor ||
      o.borderThickness != borderThickness;
}
