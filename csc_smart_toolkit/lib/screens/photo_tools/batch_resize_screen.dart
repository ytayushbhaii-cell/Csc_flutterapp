import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../services/photo_service.dart';
import '../../providers/history_provider.dart';

class BatchResizeScreen extends StatefulWidget {
  const BatchResizeScreen({super.key});
  @override
  State<BatchResizeScreen> createState() => _BatchResizeScreenState();
}

class _BatchResizeScreenState extends State<BatchResizeScreen> {
  List<Uint8List> _images = [];
  List<Uint8List> _results = [];
  bool _isProcessing = false;
  double _progress = 0;
  bool _keepAspect = true;
  final _wCtrl = TextEditingController(text: '800');

  @override
  void dispose() { _wCtrl.dispose(); super.dispose(); }

  Future<void> _pickImages() async {
    final images = await PhotoService.pickMultipleImages();
    if (images.isEmpty) return;
    setState(() { _images = images; _results = []; });
  }

  Future<void> _process() async {
    if (_images.isEmpty) return;
    final w = int.tryParse(_wCtrl.text) ?? 800;
    setState(() { _isProcessing = true; _results = []; _progress = 0; });

    final results = <Uint8List>[];
    for (int i = 0; i < _images.length; i++) {
      final result = await compute(_resizeOne, {'bytes': _images[i], 'w': w});
      results.add(result);
      if (mounted) setState(() => _progress = (i + 1) / _images.length);
    }

    if (!mounted) return;
    setState(() { _results = results; _isProcessing = false; });
    context.read<HistoryProvider>().recordUsage(
        toolId: 'batch-resize', toolName: 'Batch Resize', category: 'Photo Tools');
  }

  static Uint8List _resizeOne(Map<String, dynamic> args) {
    final image = img.decodeImage(args['bytes'] as Uint8List);
    if (image == null) return args['bytes'] as Uint8List;
    final resized = img.copyResize(image, width: args['w'] as int,
        interpolation: img.Interpolation.cubic);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 92));
  }

  Future<void> _saveAll() async {
    for (int i = 0; i < _results.length; i++) {
      final filename = PhotoService.timestampFilename('batch_${i + 1}', 'jpg');
      await PhotoService.saveToDocuments(_results[i], filename);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_results.length} photos saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Resize'),
        actions: [
          if (_results.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Save All'),
              onPressed: _saveAll,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _wCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Target Width (px)', suffixText: 'px'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Keep Aspect Ratio'),
                      value: _keepAspect,
                      onChanged: (v) => setState(() => _keepAspect = v),
                      contentPadding: EdgeInsets.zero, dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pick images button
            OutlinedButton.icon(
              icon: const Icon(Icons.burst_mode_outlined),
              label: Text(_images.isEmpty ? 'Select Photos' : 'Change Photos (${_images.length} selected)'),
              onPressed: _pickImages,
            ),
            const SizedBox(height: 12),

            // Process button
            if (_images.isNotEmpty && !_isProcessing)
              FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: Text('Resize ${_images.length} Photos'),
                onPressed: _process,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),

            // Progress
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    LinearProgressIndicator(value: _progress,
                        borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).round()}% — Processing ${_images.length} images…',
                        style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
            ],

            // Results grid
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Results (${_results.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _results.length,
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_results[i], fit: BoxFit.cover),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
