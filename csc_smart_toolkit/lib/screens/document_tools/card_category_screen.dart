import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable tool-grid screen for any ID-card category.
class CardCategoryScreen extends StatelessWidget {
  const CardCategoryScreen({
    super.key,
    required this.title,
    required this.color,
    required this.tools,
  });

  final String title;
  final Color color;
  final List<CardToolEntry> tools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(t.route),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: t.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t.icon, color: t.color, size: 22),
                    ),
                    const Spacer(),
                    Text(t.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(title,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withAlpha(130))),
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

class CardToolEntry {
  const CardToolEntry(this.name, this.icon, this.color, this.route);
  final String name;
  final IconData icon;
  final Color color;
  final String route;
}
