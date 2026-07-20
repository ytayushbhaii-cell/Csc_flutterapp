import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PhotoToolsScreen extends StatelessWidget {
  const PhotoToolsScreen({super.key});

  static const List<_PhotoEntry> _tools = [
    _PhotoEntry('Background Remove', Icons.image_outlined, Color(0xFF8B5CF6), '/photo-tools/background-remove'),
    _PhotoEntry('Passport Photo', Icons.badge_outlined, Color(0xFF2563EB), '/photo-tools/passport-photo'),
    _PhotoEntry('Visa Photo', Icons.airplane_ticket_outlined, Color(0xFF0891B2), '/photo-tools/visa-photo'),
    _PhotoEntry('Stamp Size Photo', Icons.approval_outlined, Color(0xFF059669), '/photo-tools/stamp-photo'),
    _PhotoEntry('Photo Resize', Icons.photo_size_select_large_outlined, Color(0xFFD97706), '/photo-tools/resize'),
    _PhotoEntry('Photo Compress', Icons.compress, Color(0xFF16A34A), '/photo-tools/compress'),
    _PhotoEntry('Photo Enhance', Icons.auto_fix_high_outlined, Color(0xFF7C3AED), '/photo-tools/enhance'),
    _PhotoEntry('Brightness', Icons.brightness_6_outlined, Color(0xFFF59E0B), '/photo-tools/brightness'),
    _PhotoEntry('Contrast', Icons.contrast, Color(0xFF0891B2), '/photo-tools/contrast'),
    _PhotoEntry('Sharpen', Icons.deblur_outlined, Color(0xFF6366F1), '/photo-tools/sharpen'),
    _PhotoEntry('Rotate', Icons.rotate_right, Color(0xFFDC2626), '/photo-tools/rotate'),
    _PhotoEntry('Mirror / Flip', Icons.flip_outlined, Color(0xFFDB2777), '/photo-tools/mirror'),
    _PhotoEntry('Crop', Icons.crop_outlined, Color(0xFF0D9488), '/photo-tools/crop'),
    _PhotoEntry('Face Center', Icons.face_outlined, Color(0xFF7C3AED), '/photo-tools/face-center'),
    _PhotoEntry('Batch Resize', Icons.burst_mode_outlined, Color(0xFF1D4ED8), '/photo-tools/batch-resize'),
    _PhotoEntry('White Background', Icons.wb_sunny_outlined, Color(0xFF64748B), '/photo-tools/white-background'),
    _PhotoEntry('Blue Background', Icons.water_outlined, Color(0xFF2563EB), '/photo-tools/blue-background'),
    _PhotoEntry('Red Background', Icons.circle_outlined, Color(0xFFDC2626), '/photo-tools/red-background'),
    _PhotoEntry('Transparent PNG', Icons.layers_clear_outlined, Color(0xFF475569), '/photo-tools/transparent-png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Tools')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final t = _tools[i];
          return _ToolCard(entry: t);
        },
      ),
    );
  }
}

class _PhotoEntry {
  const _PhotoEntry(this.name, this.icon, this.color, this.route);
  final String name;
  final IconData icon;
  final Color color;
  final String route;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.entry});
  final _PhotoEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(entry.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: entry.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.icon, color: entry.color, size: 22),
              ),
              const Spacer(),
              Text(
                entry.name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Photo Tools',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurface.withAlpha(130)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
