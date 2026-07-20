import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/passport_photo_service.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/photo_tool_scaffold.dart';

/// Passport / Visa / Stamp Photo Maker.
/// [initialTab]: 0=Passport, 1=Visa, 2=Stamp
class PassportPhotoScreen extends StatefulWidget {
  const PassportPhotoScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<PassportPhotoScreen> createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen>
    with PhotoToolMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _copies = 4;

  @override
  String get toolIdBase => 'passport-photo';
  @override
  String get toolNameBase => 'Passport Photo';

  PhotoSize get _currentSize =>
      PhotoSize.all[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (originalBytes == null) return;
    setState(() { isProcessing = true; progress = 0.2; progressStage = 'Preparing…'; });
    try {
      final result = await PassportPhotoService.makePhoto(
        originalBytes!,
        _currentSize,
        copies: _copies,
      );
      if (!mounted) return;
      setState(() {
        resultBytes = result;
        isProcessing = false;
        progress = 1.0;
        progressStage = 'Done';
      });
      context.read<HistoryProvider>().recordUsage(
            toolId: toolIdBase, toolName: _currentSize.label, category: 'Photo Tools');
    } catch (e) {
      if (!mounted) return;
      setState(() { isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhotoToolScaffold(
      title: 'Photo Maker',
      toolId: toolIdBase,
      category: 'Photo Tools',
      originalBytes: originalBytes,
      resultBytes: resultBytes,
      isProcessing: isProcessing,
      progress: progress,
      progressStage: progressStage,
      onPickImage: pickImageBase,
      onProcess: _process,
      onReset: resetBase,
      onSave: saveBase,
      onShare: shareBase,
      processLabel: 'Make ${_currentSize.label.split('(').first.trim()}',
      processIcon: Icons.badge_outlined,
      canProcess: originalBytes != null && !isProcessing,
      controlsSection: Card(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Passport'),
                Tab(text: 'Visa'),
                Tab(text: 'Stamp'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SizeInfo(size: _currentSize),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Copies on A4 sheet',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                          iconSize: 20,
                        ),
                        Text('$_copies',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _copies < 20
                              ? () => setState(() => _copies++)
                              : null,
                          iconSize: 20,
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeInfo extends StatelessWidget {
  const _SizeInfo({required this.size});
  final PhotoSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.straighten, color: cs.primary, size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(size.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Text('${size.widthPx} × ${size.heightPx} px @ 300 DPI',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withAlpha(160))),
        ]),
      ]),
    );
  }
}
