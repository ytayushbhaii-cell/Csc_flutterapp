import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/id_card_service.dart';

const _kColor = Color(0xFF6366F1);

class QrIdScreen extends StatefulWidget {
  const QrIdScreen({super.key});

  @override
  State<QrIdScreen> createState() => _QrIdScreenState();
}

class _QrIdScreenState extends State<QrIdScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _idCtrl   = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _orgCtrl  = TextEditingController(text: 'ABC Organization');
  final _qrCtrl   = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _photoPath;
  bool _showBack  = false;
  bool _exporting = false;
  final _repaintKey = GlobalKey();
  late final TabController _tabCtrl;

  String get _qrValue {
    if (_qrCtrl.text.isNotEmpty) return _qrCtrl.text;
    final name = _nameCtrl.text.isEmpty ? 'Name' : _nameCtrl.text;
    final id   = _idCtrl.text.isEmpty   ? 'ID'   : _idCtrl.text;
    final org  = _orgCtrl.text.isEmpty  ? 'Org'  : _orgCtrl.text;
    return 'Name: $name\nID: $id\nOrg: $org\nPhone: ${_phoneCtrl.text}';
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _showBack = _tabCtrl.index == 1));
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _idCtrl, _roleCtrl, _orgCtrl, _qrCtrl, _phoneCtrl]) c.dispose();
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
        final pdf = await IDCardService.pngToPdf(png, title: 'QR ID Card');
        file = File('${dir.path}/QR_ID_$ts.pdf');
        await file.writeAsBytes(pdf);
      } else {
        file = File('${dir.path}/QR_ID_$ts.png');
        await file.writeAsBytes(png);
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'QR ID Card'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'qr-id', toolName: 'QR Enabled ID', category: 'ID Card Tools',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _reset() => setState(() {
    for (final c in [_nameCtrl, _idCtrl, _roleCtrl, _phoneCtrl, _qrCtrl]) c.clear();
    _orgCtrl.text = 'ABC Organization'; _photoPath = null;
    _showBack = false; _tabCtrl.index = 0;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Enabled ID Card'),
        backgroundColor: cs.surface,
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _reset)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'Front'), Tab(text: 'Back (QR)')],
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
                      ? _QRCardBack(qrValue: _qrValue, name: _nameCtrl.text, org: _orgCtrl.text)
                      : _QRCardFront(
                          name: _nameCtrl.text, idNo: _idCtrl.text,
                          role: _roleCtrl.text, org: _orgCtrl.text,
                          phone: _phoneCtrl.text, photoPath: _photoPath),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _lbl(theme, cs, 'PHOTO'),
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
          _lbl(theme, cs, 'DETAILS'),
          const SizedBox(height: 8),
          ...[
            ('Full Name',         _nameCtrl,  TextInputType.text),
            ('ID Number',         _idCtrl,    TextInputType.text),
            ('Role / Designation',_roleCtrl,  TextInputType.text),
            ('Organization',      _orgCtrl,   TextInputType.text),
            ('Phone Number',      _phoneCtrl, TextInputType.phone),
          ].map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: r.$2, onChanged: (_) => setState(() {}), keyboardType: r.$3,
              decoration: InputDecoration(labelText: r.$1, border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          )),
          _lbl(theme, cs, 'CUSTOM QR DATA (optional — leave blank to auto-generate)'),
          const SizedBox(height: 8),
          TextField(
            controller: _qrCtrl, onChanged: (_) => setState(() {}),
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Custom text or URL for QR code',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          ),
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

class _QRCardFront extends StatelessWidget {
  const _QRCardFront({
    required this.name, required this.idNo, required this.role,
    required this.org, required this.phone, this.photoPath,
  });
  final String name, idNo, role, org, phone;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
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
              color: Color(0xFF3730A3),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.qr_code, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(org.isEmpty ? 'Organization' : org,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
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
            Text(name.isEmpty ? 'Full Name' : name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            _row('ID',    idNo.isEmpty  ? '—' : idNo),
            _row('Role',  role.isEmpty  ? '—' : role),
            if (phone.isNotEmpty) _row('Ph', phone),
          ]),
        ),
        const Positioned(bottom: 8, left: 12, right: 12,
            child: Text('FLIP FOR QR CODE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 1.5))),
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

class _QRCardBack extends StatelessWidget {
  const _QRCardBack({required this.qrValue, required this.name, required this.org});
  final String qrValue, name, org;

  @override
  Widget build(BuildContext context) {
    final safeQR = qrValue.isEmpty ? 'ID Card' : qrValue;
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
              color: Colors.white, border: Border.all(color: const Color(0xFF6366F1).withAlpha(80)),
              borderRadius: BorderRadius.circular(8)),
          child: QrImageView(data: safeQR, version: QrVersions.auto, size: 130),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('SCAN TO VERIFY',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: Color(0xFF6366F1))),
            const SizedBox(height: 8),
            Text(name.isEmpty ? 'Name' : name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(org.isEmpty ? 'Organization' : org,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}
