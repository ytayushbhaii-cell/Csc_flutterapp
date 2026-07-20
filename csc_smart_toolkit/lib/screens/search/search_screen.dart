import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/navigation_service.dart';
import '../../data/tools_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();
    final favProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search tools…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _controller.clear();
                      searchProvider.clear();
                    },
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: (q) => searchProvider.setQuery(q),
          onSubmitted: (q) => searchProvider.submitQuery(q),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: searchProvider.hasQuery
          ? _ResultsList(
              results: searchProvider.results,
              query: searchProvider.query,
              favProvider: favProvider,
            )
          : _HistoryList(
              history: searchProvider.history,
              onSelect: (q) {
                _controller.text = q;
                searchProvider.setQuery(q);
              },
              onRemove: searchProvider.removeHistoryItem,
              onClearAll: searchProvider.clearHistory,
              recentTools: allTools,
              favProvider: favProvider,
            ),
    );
  }
}

// ── Results ────────────────────────────────────────────────────────────────
class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.query,
    required this.favProvider,
  });

  final List<ToolModel> results;
  final String query;
  final FavoritesProvider favProvider;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: 12),
            Text('No results for "$query"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140))),
          ],
        ),
      );
    }

    // Group by category
    final grouped = <String, List<ToolModel>>{};
    for (final t in results) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, si) {
        final section = sections[si];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (si > 0) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(section.key.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      )),
            ),
            ...section.value.map((tool) => _ToolListTile(
                  tool: tool,
                  isFavorite: favProvider.isFavorite(tool.id),
                  onFavorite: () => favProvider.toggle(tool.id),
                )),
          ],
        );
      },
    );
  }
}

class _ToolListTile extends StatelessWidget {
  const _ToolListTile({
    required this.tool,
    required this.isFavorite,
    required this.onFavorite,
  });

  final ToolModel tool;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tool.color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(tool.icon, color: tool.color, size: 22),
        ),
        title: Text(tool.name,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(tool.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withAlpha(140))),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? const Color(0xFFEF4444) : cs.onSurface.withAlpha(120),
            size: 20,
          ),
          onPressed: onFavorite,
        ),
        onTap: () => NavigationService.goTool(context, tool.route),
      ),
    );
  }
}

// ── History ────────────────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.history,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
    required this.recentTools,
    required this.favProvider,
  });

  final List<String> history;
  final void Function(String) onSelect;
  final void Function(String) onRemove;
  final VoidCallback onClearAll;
  final List<ToolModel> recentTools;
  final FavoritesProvider favProvider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Clear'),
                onPressed: onClearAll,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((q) {
              return ActionChip(
                avatar: const Icon(Icons.history, size: 16),
                label: Text(q),
                onPressed: () => onSelect(q),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(60)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('All Tools (${recentTools.length})',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...recentTools.map((tool) => _ToolListTile(
              tool: tool,
              isFavorite: favProvider.isFavorite(tool.id),
              onFavorite: () => favProvider.toggle(tool.id),
            )),
      ],
    );
  }
}
