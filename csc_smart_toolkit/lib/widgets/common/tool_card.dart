import 'package:flutter/material.dart';
import '../../models/tool_model.dart';

/// Reusable grid card shown on Dashboard, Favorites, etc.
class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.showOpenButton = false,
  });

  final ToolModel tool;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool showOpenButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tool.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(tool.icon, color: tool.color, size: 20),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite
                          ? const Color(0xFFEF4444)
                          : cs.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                tool.name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                tool.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(130),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showOpenButton) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: tool.color.withAlpha(120)),
                      foregroundColor: tool.color,
                      textStyle: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Open Tool'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
