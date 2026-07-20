import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QRToolsScreen extends StatelessWidget {
  const QRToolsScreen({super.key});

  static const _tools = [
    _Entry('QR Generator', Icons.qr_code_2_outlined,       Color(0xFF8B5CF6), '/qr-tools/generator'),
    _Entry('QR Scanner',   Icons.qr_code_scanner_outlined, Color(0xFF8B5CF6), '/qr-tools/scanner'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('QR Tools')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('QR Code Tools',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Generate and scan QR codes — fully offline, no internet required.',
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
              Text('QR Tools',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurface.withAlpha(130))),
            ],
          ),
        ),
      ),
    );
  }
}
