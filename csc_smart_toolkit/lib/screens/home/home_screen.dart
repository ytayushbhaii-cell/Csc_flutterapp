import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSC Smart Toolkit'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.offline_bolt,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Offline Ready',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All tools work without internet. Your data stays on your device.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick access section
              Text(
                'Quick Access',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: const [
                  _ToolCard(
                    icon: Icons.document_scanner_outlined,
                    label: 'Document Tools',
                    subtitle: 'Aadhaar, PAN, Passport',
                    color: Color(0xFF1D4ED8),
                  ),
                  _ToolCard(
                    icon: Icons.image_outlined,
                    label: 'Photo Tools',
                    subtitle: 'Edit, enhance & crop',
                    color: Color(0xFF7C3AED),
                  ),
                  _ToolCard(
                    icon: Icons.badge_outlined,
                    label: 'ID Card Tools',
                    subtitle: 'Student, Employee & more',
                    color: Color(0xFF059669),
                  ),
                  _ToolCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Barcode Tools',
                    subtitle: 'Scan & generate',
                    color: Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tools section placeholder
              Text(
                'All Tools',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.construction_outlined,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tools coming in Part 2',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Full tool pages will be added in the next phase.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
