import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/id_card_service.dart';

const _kColor = Color(0xFF059669);

class EmployeeIdScreen extends StatefulWidget {
  const EmployeeIdScreen({super.key});

  @override
  State<EmployeeIdScreen> createState() => _EmployeeIdScreenState();
}

class _EmployeeIdScreenState extends State<EmployeeIdScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _desgCtrl  = TextEditingController();
  final _deptCtrl  = TextEditingController();
  final _compCtrl  = TextEditingController(text: 'ABC Company Pvt Ltd');
  final _bloodCtrl = TextEditingController();
  final _joinCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

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
    for (final c in [_nameCtrl, _empIdCtrl, _desgCtrl, _deptCtrl,
        _compCtrl, _bloodCtrl, _joinCtrl, _phoneCtrl]) c.dispose();
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
        final pdf = await IDCardService.pngToPdf(png, title: 'Employee ID');
        file = File('${dir.path}/EmployeeID_$ts.pdf');
        await file.writeAsBytes(pdf);
      } else {
        file = File('${dir.path}/EmployeeID_$ts.png');
        await file.writeAsBytes(png);
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Employee ID Card'));
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'employee-id', toolName: 'Employee ID Card', category: 'ID Card Tools',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _reset() => setState(() {
    _nameCtrl.clear(); _empIdCtrl.clear(); _desgCtrl.clear(); _deptCtrl.clear();
    _bloodCtrl.clear(); _joinCtrl.clear(); _phoneCtrl.clear();
    _compCtrl.text = 'ABC Company Pvt Ltd'; _photoPath = null;
    _showBack = false; _tabCtrl.index = 0;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee ID Card'),
        backgroundColor: cs.surface,
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _reset)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TabBar(controller: _tabCtrl,
              tabs: const [Tab(text: 'Front'), Tab(text: 'Back')],
              labelColor: _kColor, indicatorColor: _kColor),
          const SizedBox(height: 12),
          _label(theme, cs, 'PREVIEW'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _showBack
                      ? _EmployeeCardBack(phone: _phoneCtrl.text, blood: _bloodCtrl.text, company: _compCtrl.text)
                      : _EmployeeCardFront(
                          name: _nameCtrl.text, empId: _empIdCtrl.text,
                          designation: _desgCtrl.text, department: _deptCtrl.text,
                          company: _compCtrl.text, joining: _joinCtrl.text, photoPath: _photoPath),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(theme, cs, 'EMPLOYEE PHOTO'),
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
          _label(theme, cs, 'EMPLOYEE DETAILS'),
          const SizedBox(height: 8),
          ..._buildFields(theme),
          const SizedBox(height: 16),
          _label(theme, cs, 'EXPORT'),
          const SizedBox(height: 8),
          _exporting
              ? const Center(child: CircularProgressIndicator())
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  _btn('PNG',   () => _export('png'),  const Color(0xFF059669), Icons.image_outlined),
                  _btn('PDF',   () => _export('pdf'),  const Color(0xFFDC2626), Icons.picture_as_pdf_outlined),
                  _btn('Share', () => _export('png'),  const Color(0xFF6366F1), Icons.share_outlined),
                ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(ThemeData t, ColorScheme cs, String s) => Text(s,
      style: t.textTheme.labelSmall?.copyWith(color: cs.onSurface.withAlpha(160), letterSpacing: 0.8));

  Widget _btn(String label, VoidCallback cb, Color color, IconData icon) =>
      ElevatedButton.icon(
        onPressed: cb, icon: Icon(icon, size: 16), label: Text(label),
        style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );

  List<Widget> _buildFields(ThemeData t) {
    final rows = [
      ('Employee Name',   _nameCtrl,  TextInputType.text),
      ('Employee ID',     _empIdCtrl, TextInputType.text),
      ('Designation',     _desgCtrl,  TextInputType.text),
      ('Department',      _deptCtrl,  TextInputType.text),
      ('Company Name',    _compCtrl,  TextInputType.text),
      ('Blood Group',     _bloodCtrl, TextInputType.text),
      ('Joining Date',    _joinCtrl,  TextInputType.datetime),
      ('Phone Number',    _phoneCtrl, TextInputType.phone),
    ];
    return rows.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: r.$2, onChanged: (_) => setState(() {}), keyboardType: r.$3,
        decoration: InputDecoration(
            labelText: r.$1, border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      ),
    )).toList();
  }
}

class _EmployeeCardFront extends StatelessWidget {
  const _EmployeeCardFront({
    required this.name, required this.empId, required this.designation,
    required this.department, required this.company, required this.joining,
    this.photoPath,
  });
  final String name, empId, designation, department, company, joining;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF059669)],
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
              color: Color(0xFF064E3B),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.business, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(company.isEmpty ? 'Company Name' : company,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
        Positioned(
          top: 58, left: 12,
          child: Container(
            width: 72, height: 88,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(6),
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
            Text(name.isEmpty ? 'Employee Name' : name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            _row('ID', empId.isEmpty ? '—' : empId),
            _row('Role', designation.isEmpty ? '—' : designation),
            _row('Dept', department.isEmpty ? '—' : department),
            if (joining.isNotEmpty) _row('Joined', joining),
          ]),
        ),
        const Positioned(bottom: 8, left: 12, right: 12,
            child: Text('EMPLOYEE IDENTITY CARD',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1.5))),
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

class _EmployeeCardBack extends StatelessWidget {
  const _EmployeeCardBack({required this.phone, required this.blood, required this.company});
  final String phone, blood, company;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 202,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF059669), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EMERGENCY INFO',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                letterSpacing: 1, color: Color(0xFF059669))),
        const SizedBox(height: 8),
        _row(Icons.business, company.isEmpty ? 'Company Name' : company),
        const SizedBox(height: 4),
        _row(Icons.phone, phone.isEmpty ? '—' : phone),
        if (blood.isNotEmpty) ...[const SizedBox(height: 4), _row(Icons.bloodtype, 'Blood: $blood')],
        const Spacer(),
        const Divider(height: 1),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Signature:', style: TextStyle(fontSize: 9, color: Colors.black45)),
          Container(width: 80, height: 0.5, color: Colors.black26),
        ]),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
    Icon(icon, size: 12, color: const Color(0xFF059669)),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
  ]);
}
