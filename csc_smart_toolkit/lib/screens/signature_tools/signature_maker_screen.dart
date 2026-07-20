import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signature/signature.dart';

import '../../providers/history_provider.dart';
import '../../services/signature_service.dart';

const _kSigColor = Color(0xFFEC4899);

/// Shared signature drawing screen.
class SignatureMakerScreen extends StatefulWidget {
  const SignatureMakerScreen({
    super.key,
    this.title = 'Signature Maker',
    this.transparentBackground = false,
    this.whiteBackground = false,
    this.toolId = 'signature-maker',
  });

  final String title;
  final bool transparentBackground;
  final bool whiteBackground;
  final String toolId;

  @override
  State<SignatureMakerScreen> createState() => _SignatureMakerScreenState();
}

class _SignatureMakerScreenState extends State<SignatureMakerScreen> {
  SignatureController _controller = SignatureController();
  Color _penColor = Colors.black;
  double _penStroke = 3.0;
  bool _transparentBg = false;
  bool _exporting = false;

  static const _penColors = [
    Colors.black, Color(0xFF1D4ED8), Color(0xFFEC4899),
    Color(0xFF059669), Color(0xFFDC2626),
  ];
  static const _penSizes = [2.0, 3.0, 5.0, 8.0];

  @override
  void initState() {
    super.initState();
    _transparentBg = widget.transparentBackground;
    _buildController();
  }

  void _buildController() {
    _controller.dispose();
    _controller = SignatureController(
      penStrokeWidth: _penStroke,
      penColor: _penColor,
      exportBackgroundColor:
          _transparentBg ? Colors.transparent : Colors.white,
    );
    // Note: point restoration not supported by signature package v5 API
    // Drawing is cleared when pen settings change
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasDrawing => _controller.isNotEmpty;

  Future<Uint8List?> _captureSignature() async {
    final image = await _controller.toImage();
    if (image == null) return null;
    return SignatureService.uiImageToPng(image);
  }

  Future<void> _exportPng() async {
    if (!_hasDrawing) {
      _showSnack('Please draw your signature first');
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await _captureSignature();
      if (bytes == null) throw Exception('Failed to capture signature');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Signature'));
      _recordHistory();
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (!_hasDrawing) {
      _showSnack('Please draw your signature first');
      return;
    }
    setState(() => _exporting = true);
    try {
      final pngBytes = await _captureSignature();
      if (pngBytes == null) throw Exception('Failed to capture signature');
      final pdfBytes =
          await SignatureService.pngToPdf(pngBytes, title: widget.title);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Signature_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Signature PDF'));
      _recordHistory();
    } catch (e) {
      _showSnack('PDF export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() async {
    if (!_hasDrawing) {
      _showSnack('Please draw your signature first');
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await _captureSignature();
      if (bytes == null) throw Exception('Failed to capture signature');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Signature_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      _showSnack('Share failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _recordHistory() {
    if (!mounted) return;
    context.read<HistoryProvider>().recordUsage(
          toolId: widget.toolId,
          toolName: widget.title,
          category: 'Signature Tools',
        );
  }

  void _showSnack(String msg) {
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
        title: Text(widget.title),
        backgroundColor: cs.surface,
        actions: [
          TextButton(
            onPressed: () {
              _controller.undo();
              setState(() {});
            },
            child: Text('Undo', style: TextStyle(color: _kSigColor)),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              setState(() {});
            },
            child: Text('Clear', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Canvas ────────────────────────────────────────────────────────
          Text('DRAW SIGNATURE',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _kSigColor.withAlpha(120), width: 1.5),
            ),
            child: Container(
              height: 240,
              color: _transparentBg
                  ? _checkerboardColor(theme.brightness)
                  : Colors.white,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.transparent,
                width: double.infinity,
                height: 240,
              ),
            ),
          ),
          if (!_hasDrawing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text('Draw here ↑',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha(100))),
              ),
            ),
          const SizedBox(height: 16),

          // ── Pen color ─────────────────────────────────────────────────────
          Text('PEN COLOR',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: _penColors.map((c) {
              final sel = _penColor == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _penColor = c;
                      _buildController();
                    });
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: _kSigColor, width: 2.5)
                          : Border.all(
                              color: cs.outline.withAlpha(60), width: 1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Pen size ──────────────────────────────────────────────────────
          Text('PEN THICKNESS',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: _penSizes.map((s) {
              final sel = _penStroke == s;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _penStroke = s;
                        _buildController();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: sel ? _kSigColor : cs.onSurface,
                      side: BorderSide(
                          color: sel ? _kSigColor : cs.outline.withAlpha(100)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor:
                          sel ? _kSigColor.withAlpha(20) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: s * 2 + 4,
                          height: s * 2 + 4,
                          decoration: BoxDecoration(
                            color: sel ? _kSigColor : cs.onSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${s.toInt()}',
                            style: const TextStyle(fontSize: 12)),
                      ],
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
                activeColor: _kSigColor,
                onChanged: (v) {
                  setState(() {
                    _transparentBg = v;
                    _buildController();
                  });
                },
              ),
              const SizedBox(width: 8),
              Text('Transparent background',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),

          // ── Export ────────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: !_exporting ? _exportPng : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kSigColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.download_outlined),
            label: Text(_exporting ? 'Exporting…' : 'Export PNG'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !_exporting ? _exportPdf : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kSigColor,
              side: BorderSide(color: _kSigColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !_exporting ? _share : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kSigColor,
              side: BorderSide(color: _kSigColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          const SizedBox(height: 12),
          Card(
            color: _kSigColor.withAlpha(15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _kSigColor.withAlpha(60))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: _kSigColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enable "Transparent" for a PNG with no background — '
                      'perfect for stamping on documents.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(160)),
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

  Color _checkerboardColor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF2D2D2D)
          : const Color(0xFFF0F0F0);
}
