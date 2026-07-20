import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentToolsScreen extends StatelessWidget {
  const DocumentToolsScreen({super.key});

  static const _cats = [
    _Cat('Aadhaar Tools', Icons.badge_outlined, Color(0xFF1D4ED8),
        '/document-tools/aadhaar', '11 tools'),
    _Cat('PAN Card Tools', Icons.credit_card_outlined, Color(0xFFD97706),
        '/document-tools/pan', '4 tools'),
    _Cat('Voter ID Tools', Icons.how_to_vote_outlined, Color(0xFF059669),
        '/document-tools/voter', '2 tools'),
    _Cat('Driving License', Icons.drive_eta_outlined, Color(0xFF7C3AED),
        '/document-tools/driving-license', '2 tools'),
    _Cat('Passport Tools', Icons.book_outlined, Color(0xFF0891B2),
        '/document-tools/passport', '3 tools'),
    _Cat('PDF Tools', Icons.picture_as_pdf_outlined, Color(0xFFDC2626),
        '/document-tools/pdf', '9 tools'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Document Tools')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = _cats[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(c.route),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(c.icon, color: c.color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(c.subtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(130))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.outline),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Cat {
  const _Cat(this.name, this.icon, this.color, this.route, this.subtitle);
  final String name;
  final IconData icon;
  final Color color;
  final String route;
  final String subtitle;
}
