import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/tool_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/history_provider.dart';
import '../../data/tools_data.dart';
import '../../services/navigation_service.dart';
import '../../widgets/common/tool_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final favProvider = context.watch<FavoritesProvider>();
    final histProvider = context.watch<HistoryProvider>();

    final favTools = favProvider.favoriteTools(allTools);
    final topIds = histProvider.topToolIds();
    final mostUsed = topIds.isEmpty
        ? mostUsedTools
        : allTools.where((t) => topIds.contains(t.id)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.offline_bolt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('CSC Smart Toolkit',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => NavigationService.goSearch(context),
                tooltip: 'Search',
              ),
              IconButton(
                icon: Icon(themeProvider.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome Banner ──────────────────────────────────────
                  _WelcomeBanner(),
                  const SizedBox(height: 16),

                  // ── Inline Search Bar ───────────────────────────────────
                  _SearchBar(),
                  const SizedBox(height: 20),

                  // ── Stats Row ───────────────────────────────────────────
                  _StatsRow(
                    totalTools: allTools.length,
                    favorites: favTools.length,
                    history: histProvider.entries.length,
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Access ────────────────────────────────────────
                  const _SectionTitle(title: 'Quick Access'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Quick Access grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final tool = quickAccessTools[i];
                  return ToolCard(
                    tool: tool,
                    isFavorite: favProvider.isFavorite(tool.id),
                    onTap: () => NavigationService.goTool(context, tool.route),
                    onFavorite: () => favProvider.toggle(tool.id),
                  );
                },
                childCount: quickAccessTools.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Most Used ───────────────────────────────────────────
                  _SectionTitle(title: 'Most Used'),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Most Used — horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mostUsed.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final tool = mostUsed[i];
                  return _HorizontalToolChip(tool: tool, onTap: () {
                    NavigationService.goTool(context, tool.route);
                  });
                },
              ),
            ),
          ),

          // ── Favorites Section ─────────────────────────────────────────
          if (favTools.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Favorites'),
                    TextButton(
                      onPressed: () => NavigationService.goFavorites(context),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final tool = favTools.take(4).toList()[i];
                    return ToolCard(
                      tool: tool,
                      isFavorite: true,
                      onTap: () => NavigationService.goTool(context, tool.route),
                      onFavorite: () => favProvider.toggle(tool.id),
                    );
                  },
                  childCount: favTools.take(4).length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
              ),
            ),
          ],

          // ── Recent Activity ───────────────────────────────────────────
          if (histProvider.entries.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Recent Activity'),
                    TextButton(
                      onPressed: () => NavigationService.goHistory(context),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = histProvider.entries[i];
                    return _RecentRow(entry: entry);
                  },
                  childCount: histProvider.entries.take(5).length,
                ),
              ),
            ),
          ] else ...[
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.offline_bolt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('100% Offline',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white70)),
          ]),
          const SizedBox(height: 6),
          Text('$greeting! 👋',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('All tools work without internet.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => NavigationService.goSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Row(children: [
          Icon(Icons.search, color: cs.onSurface.withAlpha(120), size: 20),
          const SizedBox(width: 10),
          Text('Search tools…',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(120))),
        ]),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalTools,
    required this.favorites,
    required this.history,
  });

  final int totalTools;
  final int favorites;
  final int history;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Tools',
                value: '$totalTools',
                icon: Icons.construction_outlined,
                color: const Color(0xFF3B82F6))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Favorites',
                value: '$favorites',
                icon: Icons.favorite_border,
                color: const Color(0xFFEC4899))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'History',
                value: '$history',
                icon: Icons.history,
                color: const Color(0xFF10B981))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(140))),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _HorizontalToolChip extends StatelessWidget {
  const _HorizontalToolChip({required this.tool, required this.onTap});
  final ToolModel tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tool.color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tool.color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tool.color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(tool.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry});
  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.history, color: cs.primary, size: 18),
        ),
        title: Text(entry.toolName,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(entry.category,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withAlpha(140))),
        trailing: Text(
          _timeAgo(entry.timestamp as DateTime),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: cs.onSurface.withAlpha(120)),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
