import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrintToolsScreen extends StatelessWidget {
  const PrintToolsScreen({super.key});

  static const _tools = [
    _Entry('A4 Layout',       Icons.article_outlined,         Color(0xFF7C3AED), '/print-tools/a4-layout',
        'Print on A4 paper with margins'),
    _Entry('Legal Size',      Icons.description_outlined,     Color(0xFF0891B2), '/print-tools/legal-size',
        'Print on Legal (216×356 mm)'),
    _Entry('Letter Size',     Icons.note_outlined,            Color(0xFF059669), '/print-tools/letter-size',
        'Print on Letter (216×279 mm)'),
    _Entry('Photo Paper',     Icons.photo_outlined,           Color(0xFFDB2777), '/print-tools/photo-paper',
        'Print on 4×6 or 5×7 photo paper'),
    _Entry('Passport Sheet',  Icons.badge_outlined,           Color(0xFF2563EB), '/print-tools/passport-sheet',
        '8 passport photos on A4'),
    _Entry('Multiple Copies', Icons.content_copy_outlined,    Color(0xFF059669), '/print-tools/multiple-copies',
        'Auto-arrange copies on paper'),
    _Entry('Auto Center',     Icons.filter_center_focus_outlined, Color(0xFFD97706), '/print-tools/auto-center',
        'Center image on any paper'),
    _Entry('Margin Control',  Icons.space_bar_outlined,       Color(0xFF6366F1), '/print-tools/margin-control',
        'Custom margins and alignment'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Print Layout Tools'), backgroundColor: cs.surface),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Print Layout',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Layout, arrange and export images for any paper size. 100% offline.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withAlpha(140)),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _tools.length,
              itemBuilder: (ctx, i) => _ToolCard(entry: _tools[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry(this.name, this.icon, this.color, this.route, this.subtitle);
  final String name, route, subtitle;
  final IconData icon;
  final Color color;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.entry});
  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
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
              Text(entry.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(entry.subtitle,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurface.withAlpha(130)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
