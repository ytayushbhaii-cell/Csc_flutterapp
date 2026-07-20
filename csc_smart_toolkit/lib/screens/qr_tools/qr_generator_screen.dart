import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/qr_service.dart';

const _kQRColor = Color(0xFF8B5CF6);

// ─────────────────────────────────────────────────────────────────────────────

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  QRType _type = QRType.text;
  final Map<String, TextEditingController> _ctrl = {};
  Color _fgColor = Colors.black;
  Color _bgColor = Colors.white;
  bool _transparentBg = false;
  bool _exporting = false;
  final _repaintKey = GlobalKey();

  // Field controllers per type
  static const _typeFields = {
    QRType.text:    ['text'],
    QRType.url:     ['url'],
    QRType.phone:   ['phone'],
    QRType.email:   ['email', 'subject', 'body'],
    QRType.wifi:    ['ssid', 'password', 'auth'],
    QRType.contact: ['name', 'phone', 'email', 'org', 'address'],
  };

  static const _fieldLabels = {
    'text': 'Text', 'url': 'URL', 'phone': 'Phone Number',
    'email': 'Email', 'subject': 'Subject', 'body': 'Message',
    'ssid': 'Network Name (SSID)', 'password': 'Password',
    'name': 'Full Name', 'org': 'Organization', 'address': 'Address',
  };

  static const _colors = [
    Colors.black, Color(0xFF1D4ED8), Color(0xFF7C3AED),
    Color(0xFFDC2626), Color(0xFF059669), Color(0xFFD97706),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _typeFields.values.expand((v) => v).toSet()) {
      _ctrl[f] = TextEditingController();
    }
    // WiFi auth defaults to WPA
    _ctrl['auth']!.text = 'WPA';
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  Map<String, String> get _fields {
    final map = <String, String>{};
    for (final f in (_typeFields[_type] ?? [])) {
      map[f] = _ctrl[f]?.text ?? '';
    }
    return map;
  }

  String get _qrValue => QRService.buildValue(_type, _fields);
  bool get _hasValue => _qrValue.trim().isNotEmpty;

  Future<Uint8List> _capture() => QRService.captureWidget(_repaintKey);

  Future<void> _exportPng() async {
    if (!_hasValue) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/QRCode_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR Code'),
      );
      _recordHistory();
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (!_hasValue) return;
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capture();
      final pdfBytes = await QRService.pngToPdf(pngBytes);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/QRCode_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR Code PDF'),
      );
      _recordHistory();
    } catch (e) {
      _showError('PDF export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() async {
    if (!_hasValue) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/QRCode_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: _qrValue),
      );
    } catch (e) {
      _showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _recordHistory() {
    context.read<HistoryProvider>().recordUsage(
          toolId: 'qr-gen',
          toolName: 'QR Generator',
          category: 'QR & Barcode',
        );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Generator'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Type chips ────────────────────────────────────────────────────
          Text('QR TYPE', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QRType.values.map((t) {
                final sel = t == _type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.label),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _type = t;
                    }),
                    selectedColor: _kQRColor.withAlpha(40),
                    labelStyle: TextStyle(
                      color: sel ? _kQRColor : cs.onSurface,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                        color: sel ? _kQRColor : cs.outline.withAlpha(100)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fields ────────────────────────────────────────────────────────
          ...(_typeFields[_type] ?? []).map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _ctrl[f],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _fieldLabels[f] ?? f,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                obscureText: f == 'password',
                keyboardType: f == 'phone'
                    ? TextInputType.phone
                    : f == 'email'
                        ? TextInputType.emailAddress
                        : f == 'url'
                            ? TextInputType.url
                            : TextInputType.text,
              ),
            );
          }),

          // ── WiFi auth ─────────────────────────────────────────────────────
          if (_type == QRType.wifi) ...[
            Text('SECURITY', style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['WPA', 'WEP', 'nopass'].map((auth) {
                  final sel = (_ctrl['auth']?.text ?? 'WPA') == auth;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(auth),
                      selected: sel,
                      onSelected: (_) {
                        _ctrl.putIfAbsent('auth', () => TextEditingController())
                            .text = auth;
                        setState(() {});
                      },
                      selectedColor: _kQRColor.withAlpha(40),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── QR Preview ────────────────────────────────────────────────────
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: _hasValue
                    ? RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          color: _transparentBg
                              ? Colors.transparent
                              : _bgColor,
                          padding: const EdgeInsets.all(16),
                          child: QrImageView(
                            data: _qrValue,
                            version: QrVersions.auto,
                            size: 220,
                            eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: _fgColor),
                            dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _fgColor),
                            backgroundColor:
                                _transparentBg ? const Color(0x00000000) : _bgColor,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_outlined,
                              size: 80, color: cs.onSurface.withAlpha(60)),
                          const SizedBox(height: 8),
                          Text('Enter content to generate QR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withAlpha(120))),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Foreground color ──────────────────────────────────────────────
          Text('FOREGROUND COLOR', style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: _colors.map((c) {
              final sel = _fgColor == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _fgColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: _kQRColor, width: 2.5)
                          : Border.all(
                              color: cs.outline.withAlpha(60), width: 1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Background toggle ─────────────────────────────────────────────
          Row(
            children: [
              Switch(
                value: _transparentBg,
                activeColor: _kQRColor,
                onChanged: (v) => setState(() => _transparentBg = v),
              ),
              const SizedBox(width: 8),
              Text('Transparent background',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),

          // ── Export buttons ────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _hasValue && !_exporting ? _exportPng : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kQRColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.download_outlined),
            label: Text(_exporting ? 'Exporting…' : 'Export PNG'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _hasValue && !_exporting ? _exportPdf : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kQRColor,
              side: BorderSide(color: _kQRColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _hasValue && !_exporting ? _share : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kQRColor,
              side: BorderSide(color: _kQRColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
