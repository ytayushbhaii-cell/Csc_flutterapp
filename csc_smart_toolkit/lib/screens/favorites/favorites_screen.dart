import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/history_provider.dart';
import '../../data/tools_data.dart';
import '../../services/navigation_service.dart';
import '../../widgets/common/tool_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favProvider = context.watch<FavoritesProvider>();
    final histProvider = context.read<HistoryProvider>();
    final favorites = favProvider.favoriteTools(allTools);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Favorites'),
            if (favorites.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favorites.length}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
      body: favorites.isEmpty
          ? _EmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, i) {
                final tool = favorites[i];
                return ToolCard(
                  tool: tool,
                  isFavorite: true,
                  showOpenButton: true,
                  onTap: () {
                    histProvider.recordUsage(
                      toolId: tool.id,
                      toolName: tool.name,
                      category: tool.category,
                    );
                    NavigationService.goTool(context, tool.route);
                  },
                  onFavorite: () => favProvider.toggle(tool.id),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.favorite_border, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text('No Favorites Yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Tap the ♥ on any tool\nto add it here.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurface.withAlpha(140)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
