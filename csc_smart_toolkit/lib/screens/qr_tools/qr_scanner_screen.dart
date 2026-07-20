import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../services/qr_service.dart';

const _kQRColor = Color(0xFF8B5CF6);

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _cameraCtrl;
  bool _scanning = false;
  String? _result;
  String? _resultType;
  final List<_ScanRecord> _history = [];

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    super.dispose();
  }

  void _startCamera() {
    _cameraCtrl = MobileScannerController();
    setState(() {
      _scanning = true;
      _result = null;
    });
  }

  void _stopCamera() {
    _cameraCtrl?.dispose();
    _cameraCtrl = null;
    setState(() => _scanning = false);
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;
    _stopCamera();
    _setResult(value);
  }

  void _setResult(String value) {
    setState(() {
      _result = value;
      _resultType = QRService.detectType(value);
      if (_history.length >= 50) _history.removeLast();
      _history.insert(0, _ScanRecord(type: _resultType!, value: value,
          time: DateTime.now()));
    });
    context.read<HistoryProvider>().recordUsage(
          toolId: 'qr-scan',
          toolName: 'QR Scanner',
          category: 'QR & Barcode',
        );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    try {
      final controller = MobileScannerController();
      final result = await controller.analyzeImage(xFile.path);
      controller.dispose();
      final value = result?.barcodes.firstOrNull?.rawValue;
      if (value == null || value.isEmpty) {
        _showSnack('No QR code found in image');
        return;
      }
      _setResult(value);
    } catch (e) {
      _showSnack('Could not decode image: $e');
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard');
  }

  Future<void> _share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
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
        title: const Text('QR Scanner'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Camera / scan area ────────────────────────────────────────────
          if (_scanning && _cameraCtrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _cameraCtrl!,
                      onDetect: _onDetect,
                    ),
                    // Corner overlay
                    _ScanOverlay(),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _stopCamera,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Point camera at a QR code',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(140))),
            ),
          ] else ...[
            // ── Scan buttons ──────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _startCamera,
              style: FilledButton.styleFrom(
                backgroundColor: _kQRColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('Scan with Camera',
                  style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kQRColor,
                side: BorderSide(color: _kQRColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Scan from Gallery'),
            ),
          ],
          const SizedBox(height: 20),

          // ── Result card ───────────────────────────────────────────────────
          if (_result != null) ...[
            Text('RESULT', style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _kQRColor.withAlpha(120))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kQRColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_resultType ?? 'QR',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: _kQRColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, size: 20),
                              onPressed: () => _copy(_result!),
                              color: cs.onSurface.withAlpha(180),
                              tooltip: 'Copy',
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, size: 20),
                              onPressed: () => _share(_result!),
                              color: cs.onSurface.withAlpha(180),
                              tooltip: 'Share',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _result!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── History ───────────────────────────────────────────────────────
          if (_history.isNotEmpty) ...[
            Text('SCAN HISTORY', style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ..._history.map((rec) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Icon(Icons.qr_code_outlined,
                    color: _kQRColor, size: 20),
                title: Text(rec.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500)),
                subtitle: Text(rec.type,
                    style: theme.textTheme.labelSmall),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () => _copy(rec.value),
                ),
                onTap: () => setState(() => _result = rec.value),
              ),
            )),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ScanRecord {
  const _ScanRecord({required this.type, required this.value, required this.time});
  final String type;
  final String value;
  final DateTime time;
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _OverlayPainter()),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    const hw = 80.0, hh = 80.0;
    const len = 28.0, stroke = 3.0;
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Top-left
    canvas..drawLine(Offset(cx - hw, cy - hh), Offset(cx - hw + len, cy - hh), paint)
          ..drawLine(Offset(cx - hw, cy - hh), Offset(cx - hw, cy - hh + len), paint);
    // Top-right
    canvas..drawLine(Offset(cx + hw, cy - hh), Offset(cx + hw - len, cy - hh), paint)
          ..drawLine(Offset(cx + hw, cy - hh), Offset(cx + hw, cy - hh + len), paint);
    // Bottom-left
    canvas..drawLine(Offset(cx - hw, cy + hh), Offset(cx - hw + len, cy + hh), paint)
          ..drawLine(Offset(cx - hw, cy + hh), Offset(cx - hw, cy + hh - len), paint);
    // Bottom-right
    canvas..drawLine(Offset(cx + hw, cy + hh), Offset(cx + hw - len, cy + hh), paint)
          ..drawLine(Offset(cx + hw, cy + hh), Offset(cx + hw, cy + hh - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
