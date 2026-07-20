import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/id_card_service.dart';

const _kColor = Color(0xFF2563EB);

class StudentIdScreen extends StatefulWidget {
  const StudentIdScreen({super.key});

  @override
  State<StudentIdScreen> createState() => _StudentIdScreenState();
}

class _StudentIdScreenState extends State<StudentIdScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl   = TextEditingController();
  final _rollCtrl   = TextEditingController();
  final _classCtrl  = TextEditingController();
  final _dobCtrl    = TextEditingController();
  final _schoolCtrl = TextEditingController(text: 'ABC School');
  final _phoneCtrl  = TextEditingController();
  final _addrCtrl   = TextEditingController();

  String? _photoPath;
  bool _showBack  = false;
  bool _exporting = false;
  final _repaintKey = GlobalKey();
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {
      _showBack = _tabCtrl.index == 1;
    }));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _rollCtrl.dispose(); _classCtrl.dispose();
    _dobCtrl.dispose();  _schoolCtrl.dispose(); _phoneCtrl.dispose();
    _addrCtrl.dispose(); _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await captureWidget(_repaintKey, pixelRatio: 3.0);
      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;

      late File file;
      if (format == 'pdf') {
        final pdf = await IDCardService.pngToPdf(pngBytes, title: 'Student ID');
        file = File('${dir.path}/StudentID_$ts.pdf');
        await file.writeAsBytes(pdf);
      } else {
        file = File('${dir.path}/StudentID_$ts.png');
        await file.writeAsBytes(pngBytes);
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Student ID Card'),
      );
      if (!mounted) return;
      context.read<HistoryProvider>().recordUsage(
        toolId: 'student-id', toolName: 'Student ID Card', category: 'ID Card Tools',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _reset() => setState(() {
    _nameCtrl.clear(); _rollCtrl.clear(); _classCtrl.clear();
    _dobCtrl.clear();  _phoneCtrl.clear(); _addrCtrl.clear();
    _schoolCtrl.text = 'ABC School';
    _photoPath = null; _showBack = false; _tabCtrl.index = 0;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Front / Back tabs ─────────────────────────────────────────────
          TabBar(
            controller: _tabCtrl,
            tabs: const [Tab(text: 'Front'), Tab(text: 'Back')],
            labelColor: _kColor,
            indicatorColor: _kColor,
          ),
          const SizedBox(height: 12),

          // ── Live preview ──────────────────────────────────────────────────
          _sectionLabel(theme, cs, 'PREVIEW'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _showBack
                      ? _StudentCardBack(
                          phone: _phoneCtrl.text,
                          address: _addrCtrl.text,
                          school: _schoolCtrl.text,
                        )
                      : _StudentCardFront(
                          name:    _nameCtrl.text,
                          rollNo:  _rollCtrl.text,
                          className: _classCtrl.text,
                          dob:     _dobCtrl.text,
                          school:  _schoolCtrl.text,
                          photoPath: _photoPath,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Photo upload ──────────────────────────────────────────────────
          _sectionLabel(theme, cs, 'STUDENT PHOTO'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_photoPath == null ? 'Upload Photo' : 'Change Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kColor,
              side: const BorderSide(color: _kColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fields ────────────────────────────────────────────────────────
          _sectionLabel(theme, cs, 'STUDENT DETAILS'),
          const SizedBox(height: 8),
          ..._fields(theme, cs),
          const SizedBox(height: 16),

          // ── Export buttons ────────────────────────────────────────────────
          _sectionLabel(theme, cs, 'EXPORT'),
          const SizedBox(height: 8),
          _ExportRow(exporting: _exporting, onExport: _export),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData t, ColorScheme cs, String label) => Text(
        label,
        style: t.textTheme.labelSmall
            ?.copyWith(color: cs.onSurface.withAlpha(160), letterSpacing: 0.8),
      );

  List<Widget> _fields(ThemeData t, ColorScheme cs) {
    final rows = [
      ('Student Name',   _nameCtrl,   TextInputType.text),
      ('Roll Number',    _rollCtrl,   TextInputType.text),
      ('Class / Grade',  _classCtrl,  TextInputType.text),
      ('Date of Birth',  _dobCtrl,    TextInputType.datetime),
      ('School Name',    _schoolCtrl, TextInputType.text),
      ('Phone Number',   _phoneCtrl,  TextInputType.phone),
      ('Address',        _addrCtrl,   TextInputType.streetAddress),
    ];
    return rows.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: r.$2,
        onChanged: (_) => setState(() {}),
        keyboardType: r.$3,
        decoration: InputDecoration(
          labelText: r.$1,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    )).toList();
  }
}

// ── Card Preview Widgets ─────────────────────────────────────────────────────

class _StudentCardFront extends StatelessWidget {
  const _StudentCardFront({
    required this.name,
    required this.rollNo,
    required this.className,
    required this.dob,
    required this.school,
    this.photoPath,
  });

  final String name, rollNo, className, dob, school;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 202,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.school, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(school.isEmpty ? 'School Name' : school,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
          // Photo
          Positioned(
            top: 58, left: 12,
            child: Container(
              width: 72, height: 88,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.file(File(photoPath!), fit: BoxFit.cover))
                  : const Icon(Icons.person, color: Colors.white54, size: 36),
            ),
          ),
          // Info
          Positioned(
            top: 58, left: 96, right: 12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? 'Student Name' : name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              _infoRow('Roll No', rollNo.isEmpty ? '—' : rollNo),
              _infoRow('Class',   className.isEmpty ? '—' : className),
              _infoRow('DOB',     dob.isEmpty ? '—' : dob),
            ]),
          ),
          // Footer
          const Positioned(
            bottom: 8, left: 12, right: 12,
            child: Text('STUDENT IDENTITY CARD',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white60)),
          TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

class _StudentCardBack extends StatelessWidget {
  const _StudentCardBack({required this.phone, required this.address, required this.school});
  final String phone, address, school;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 202,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IF FOUND, PLEASE RETURN TO:',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 1, color: Color(0xFF2563EB))),
          const SizedBox(height: 8),
          _row(Icons.account_balance, school.isEmpty ? 'School Name' : school),
          const SizedBox(height: 4),
          _row(Icons.phone, phone.isEmpty ? '—' : phone),
          const SizedBox(height: 4),
          _row(Icons.location_on, address.isEmpty ? '—' : address),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Signature:', style: TextStyle(fontSize: 9, color: Colors.black45)),
              Container(width: 80, height: 0.5, color: Colors.black26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
    Icon(icon, size: 12, color: const Color(0xFF2563EB)),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
  ]);
}

// ── Export Action Row ─────────────────────────────────────────────────────────

class _ExportRow extends StatelessWidget {
  const _ExportRow({required this.exporting, required this.onExport});
  final bool exporting;
  final void Function(String format) onExport;

  @override
  Widget build(BuildContext context) {
    if (exporting) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _btn(context, Icons.image_outlined,         'PNG',   () => onExport('png'),  const Color(0xFF059669)),
        _btn(context, Icons.picture_as_pdf_outlined,'PDF',   () => onExport('pdf'),  const Color(0xFFDC2626)),
        _btn(context, Icons.share_outlined,         'Share', () => onExport('png'),  const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, String label,
      VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
