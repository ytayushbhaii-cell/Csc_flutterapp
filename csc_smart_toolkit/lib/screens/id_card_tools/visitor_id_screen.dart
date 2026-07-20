import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/id_card_service.dart';

const _kColor = Color(0xFF7C3AED);

class VisitorIdScreen extends StatefulWidget {
  const VisitorIdScreen({super.key});

  @override
  State<VisitorIdScreen> createState() => _VisitorIdScreenState();
}

class _VisitorIdScreenState extends State<VisitorIdScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl    = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _validCtrl   = TextEditingController();
  final _orgCtrl     = TextEditingController();
  final _hostCtrl    = TextEditingController();
  final _badgeCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  String? _photoPath;
  bool _showBack  = false;
  bool _exporting = false;
  final _repaintKey = GlobalKey();
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _showBack = _tabCtrl.index == 1));
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _purposeCtrl, _validCtrl, _orgCtrl,
        _hostCtrl, _badgeCtrl, _phoneCtrl]) c.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _photoPath = x.path);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final png = await captureWidget(_repaintKey, pixelRatio: 3.0);
      final dir = await getTemporaryDirectory();
      final ts  = DateTime.now().millisecondsSinceEpoch;
      late File file;
      if (format == 'pdf') {
        final pdf = await IDCardService.pngToPdf(png, title: 'Visitor Pass');
        file = File('${dir.path}/VisitorPass_$ts.pdf');
        await file.writeAsBytes(pdf);
      } else {
        file = File('${dir.path}/VisitorPass_$ts.png');
        await file.writeAsBytes(png);
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Visitor Pass'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'visitor-id', toolName: 'Visitor ID Card', category: 'ID Card Tools',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _reset() => setState(() {
    for (final c in [_nameCtrl, _purposeCtrl, _validCtrl, _orgCtrl,
        _hostCtrl, _badgeCtrl, _phoneCtrl]) c.clear();
    _photoPath = null; _showBack = false; _tabCtrl.index = 0;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor ID Card'),
        backgroundColor: cs.surface,
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _reset)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'Front'), Tab(text: 'Back')],
              labelColor: _kColor, indicatorColor: _kColor),
          const SizedBox(height: 12),
          _lbl(theme, cs, 'PREVIEW'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _showBack
                      ? _VisitorCardBack(phone: _phoneCtrl.text, host: _hostCtrl.text, org: _orgCtrl.text)
                      : _VisitorCardFront(
                          name: _nameCtrl.text, purpose: _purposeCtrl.text,
                          validTill: _validCtrl.text, org: _orgCtrl.text,
                          host: _hostCtrl.text, badge: _badgeCtrl.text, photoPath: _photoPath),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _lbl(theme, cs, 'VISITOR PHOTO'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_photoPath == null ? 'Upload Photo' : 'Change Photo'),
            style: OutlinedButton.styleFrom(
                foregroundColor: _kColor, side: const BorderSide(color: _kColor),
                padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
          const SizedBox(height: 16),
          _lbl(theme, cs, 'VISITOR DETAILS'),
          const SizedBox(height: 8),
          ...[
            ('Visitor Name',     _nameCtrl,    TextInputType.text),
            ('Purpose of Visit', _purposeCtrl, TextInputType.text),
            ('Valid Till',       _validCtrl,   TextInputType.datetime),
            ('Company / Org',    _orgCtrl,     TextInputType.text),
            ('Host Name',        _hostCtrl,    TextInputType.text),
            ('Badge Number',     _badgeCtrl,   TextInputType.text),
            ('Phone Number',     _phoneCtrl,   TextInputType.phone),
          ].map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: r.$2, onChanged: (_) => setState(() {}), keyboardType: r.$3,
              decoration: InputDecoration(labelText: r.$1, border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          )),
          const SizedBox(height: 16),
          _lbl(theme, cs, 'EXPORT'),
          const SizedBox(height: 8),
          _exporting
              ? const Center(child: CircularProgressIndicator())
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  _ebtn('PNG',   const Color(0xFF059669), Icons.image_outlined,          () => _export('png')),
                  _ebtn('PDF',   const Color(0xFFDC2626), Icons.picture_as_pdf_outlined, () => _export('pdf')),
                  _ebtn('Share', const Color(0xFF6366F1), Icons.share_outlined,           () => _export('png')),
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

class _VisitorCardFront extends StatelessWidget {
  const _VisitorCardFront({
    required this.name, required this.purpose, required this.validTill,
    required this.org, required this.host, required this.badge, this.photoPath,
  });
  final String name, purpose, validTill, org, host, badge;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF4C1D95),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.person_pin, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text('VISITOR PASS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              if (badge.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text('#$badge', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ]),
          ),
        ),
        Positioned(
          top: 58, left: 12,
          child: Container(
            width: 72, height: 88,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white54, width: 1.5)),
            child: photoPath != null
                ? ClipRRect(borderRadius: BorderRadius.circular(5),
                    child: Image.file(File(photoPath!), fit: BoxFit.cover))
                : const Icon(Icons.person, color: Colors.white54, size: 36),
          ),
        ),
        Positioned(
          top: 58, left: 96, right: 12,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? 'Visitor Name' : name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            _row('From',    org.isEmpty ? '—' : org),
            _row('Purpose', purpose.isEmpty ? '—' : purpose),
            _row('Host',    host.isEmpty ? '—' : host),
            if (validTill.isNotEmpty) _row('Valid', validTill),
          ]),
        ),
        const Positioned(bottom: 8, left: 12, right: 12,
            child: Text('AUTHORIZED VISITOR — NOT TRANSFERABLE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 1.2))),
      ]),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: RichText(text: TextSpan(style: const TextStyle(fontSize: 10), children: [
      TextSpan(text: '$l: ', style: const TextStyle(color: Colors.white60)),
      TextSpan(text: v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    ])),
  );
}

class _VisitorCardBack extends StatelessWidget {
  const _VisitorCardBack({required this.phone, required this.host, required this.org});
  final String phone, host, org;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('VISITOR RULES',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                letterSpacing: 1, color: Color(0xFF7C3AED))),
        const SizedBox(height: 6),
        const Text('• Must wear this badge at all times\n• Report to reception on arrival/departure\n• Accompanied by host at all times',
            style: TextStyle(fontSize: 9, color: Colors.black54, height: 1.5)),
        const Spacer(),
        const Divider(height: 1),
        const SizedBox(height: 6),
        _row(Icons.person, host.isEmpty ? 'Host: —' : 'Host: $host'),
        const SizedBox(height: 3),
        _row(Icons.phone, phone.isEmpty ? '—' : phone),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
    Icon(icon, size: 12, color: const Color(0xFF7C3AED)),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87))),
  ]);
}
