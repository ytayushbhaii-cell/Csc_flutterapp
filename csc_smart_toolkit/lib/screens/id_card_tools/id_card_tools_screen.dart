import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IDCardToolsScreen extends StatelessWidget {
  const IDCardToolsScreen({super.key});

  static const _tools = [
    _Entry('Student ID Card',  Icons.school_outlined,         Color(0xFF2563EB), '/id-card-tools/student',
        'Name, roll no, class, DOB, photo'),
    _Entry('Employee ID Card', Icons.badge_outlined,          Color(0xFF059669), '/id-card-tools/employee',
        'Name, designation, department, photo'),
    _Entry('Visitor ID Card',  Icons.person_pin_outlined,     Color(0xFF7C3AED), '/id-card-tools/visitor',
        'Name, purpose, host, valid till'),
    _Entry('QR Enabled ID',    Icons.qr_code_outlined,        Color(0xFF6366F1), '/id-card-tools/qr-id',
        'ID card with embedded QR code'),
    _Entry('Barcode ID Card',  Icons.barcode_reader,          Color(0xFFD97706), '/id-card-tools/barcode-id',
        'ID card with embedded barcode'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ID Card Tools'), backgroundColor: cs.surface),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('ID Card Tools',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Create professional ID cards with photo, QR, and barcode support.',
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
