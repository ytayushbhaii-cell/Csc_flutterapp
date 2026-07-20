import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StampMakerScreen extends StatelessWidget {
  const StampMakerScreen({super.key});

  static const _tools = [
    _Entry('Round Stamp',   Icons.circle_outlined,   Color(0xFFF43F5E), '/stamp-maker/round-stamp'),
    _Entry('Square Stamp',  Icons.crop_square_outlined, Color(0xFFF43F5E), '/stamp-maker/square-stamp'),
    _Entry('Company Stamp', Icons.business_outlined,  Color(0xFFF43F5E), '/stamp-maker/company-stamp'),
    _Entry('CSC Stamp',     Icons.location_city_outlined, Color(0xFFF43F5E), '/stamp-maker/csc-stamp'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stamp Maker')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Stamp Maker',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Create professional stamps — round, square, company, and CSC formats.',
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
                childAspectRatio: 1.15,
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
  const _Entry(this.name, this.icon, this.color, this.route);
  final String name;
  final IconData icon;
  final Color color;
  final String route;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.entry});
  final _Entry entry;

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
              Text(entry.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('Stamp Maker',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurface.withAlpha(130))),
            ],
          ),
        ),
      ),
    );
  }
}
