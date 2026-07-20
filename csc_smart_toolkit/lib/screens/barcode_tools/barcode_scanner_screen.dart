import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/history_provider.dart';

const _kBarcodeColor = Color(0xFF7C3AED);

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _cameraCtrl;
  bool _scanning = false;
  String? _result;
  String? _format;
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
    final fmt = barcode?.format.name ?? 'Unknown';
    _stopCamera();
    _setResult(value, fmt);
  }

  void _setResult(String value, String fmt) {
    setState(() {
      _result = value;
      _format = fmt;
      if (_history.length >= 50) _history.removeLast();
      _history.insert(0,
          _ScanRecord(format: fmt, value: value, time: DateTime.now()));
    });
    context.read<HistoryProvider>().recordUsage(
          toolId: 'barcode-scan',
          toolName: 'Barcode Scanner',
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
      final barcode = result?.barcodes.firstOrNull;
      final value = barcode?.rawValue;
      if (value == null || value.isEmpty) {
        _showSnack('No barcode found in image');
        return;
      }
      _setResult(value, barcode?.format.name ?? 'Unknown');
    } catch (e) {
      _showSnack('Could not decode image: $e');
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard');
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
        title: const Text('Barcode Scanner'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    _BarcodeOverlay(),
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
              child: Text('Point camera at a barcode',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(140))),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _startCamera,
              style: FilledButton.styleFrom(
                backgroundColor: _kBarcodeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan with Camera',
                  style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBarcodeColor,
                side: BorderSide(color: _kBarcodeColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Scan from Gallery'),
            ),
          ],
          const SizedBox(height: 20),

          if (_result != null) ...[
            Text('RESULT', style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _kBarcodeColor.withAlpha(120))),
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
                            color: _kBarcodeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_format ?? 'Barcode',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: _kBarcodeColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          onPressed: () => _copy(_result!),
                          color: cs.onSurface.withAlpha(180),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _result!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_history.isNotEmpty) ...[
            Text('SCAN HISTORY', style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(160), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ..._history.map((rec) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Icon(Icons.barcode_reader,
                    color: _kBarcodeColor, size: 20),
                title: Text(rec.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500)),
                subtitle: Text(rec.format,
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
  const _ScanRecord(
      {required this.format, required this.value, required this.time});
  final String format;
  final String value;
  final DateTime time;
}

class _BarcodeOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BarcodePainter()),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    const hw = 100.0, hh = 36.0, len = 28.0;
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(cx - hw, cy - hh), Offset(cx - hw + len, cy - hh), paint)
      ..drawLine(Offset(cx - hw, cy - hh), Offset(cx - hw, cy - hh + len), paint)
      ..drawLine(Offset(cx + hw, cy - hh), Offset(cx + hw - len, cy - hh), paint)
      ..drawLine(Offset(cx + hw, cy - hh), Offset(cx + hw, cy - hh + len), paint)
      ..drawLine(Offset(cx - hw, cy + hh), Offset(cx - hw + len, cy + hh), paint)
      ..drawLine(Offset(cx - hw, cy + hh), Offset(cx - hw, cy + hh - len), paint)
      ..drawLine(Offset(cx + hw, cy + hh), Offset(cx + hw - len, cy + hh), paint)
      ..drawLine(Offset(cx + hw, cy + hh), Offset(cx + hw, cy + hh - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
