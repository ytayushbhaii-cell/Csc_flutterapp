import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/history_entry.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final histProvider = context.watch<HistoryProvider>();
    final entries = histProvider.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all history',
              onPressed: () => _confirmClear(context, histProvider),
            ),
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Export history',
              onPressed: () => _exportHistory(context, entries),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: entries.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                return _HistoryRow(
                  entry: entries[i],
                  onDelete: () => histProvider.removeEntry(entries[i].id),
                );
              },
            ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all tool usage history. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.clearAll();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportHistory(BuildContext context, List<HistoryEntry> entries) {
    final buffer = StringBuffer('Tool History\n');
    buffer.writeln('='  * 40);
    for (final e in entries) {
      buffer.writeln(
          '${e.toolName} (${e.category}) — ${_formatDate(e.timestamp)}');
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export History'),
        content: SingleChildScrollView(
          child: SelectableText(buffer.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  )),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onDelete});

  final HistoryEntry entry;
  final VoidCallback onDelete;

  static const Map<String, Color> _categoryColors = {
    'QR & Barcode': Color(0xFF6D28D9),
    'Photo Tools': Color(0xFF8B5CF6),
    'Aadhaar Tools': Color(0xFF1D4ED8),
    'PAN Tools': Color(0xFFD97706),
    'PDF Tools': Color(0xFFDC2626),
    'Signature Tools': Color(0xFFDB2777),
    'Stamp Maker': Color(0xFFF59E0B),
    'ID Card Tools': Color(0xFF059669),
    'Utility Tools': Color(0xFF0891B2),
  };

  static const Map<String, IconData> _categoryIcons = {
    'QR & Barcode': Icons.qr_code,
    'Photo Tools': Icons.image_outlined,
    'Aadhaar Tools': Icons.badge_outlined,
    'PAN Tools': Icons.credit_card_outlined,
    'PDF Tools': Icons.picture_as_pdf,
    'Signature Tools': Icons.draw_outlined,
    'Stamp Maker': Icons.approval_outlined,
    'ID Card Tools': Icons.badge_outlined,
    'Utility Tools': Icons.calculate_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _categoryColors[entry.category] ?? cs.primary;
    final icon = _categoryIcons[entry.category] ?? Icons.widgets_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(entry.toolName,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(entry.category,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            Text(_timeAgo(entry.timestamp),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurface.withAlpha(120))),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              size: 18, color: cs.onSurface.withAlpha(120)),
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
        isThreeLine: false,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
          Icon(Icons.history_outlined,
              size: 64, color: cs.onSurface.withAlpha(60)),
          const SizedBox(height: 16),
          Text('No History Yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tools you use will appear here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(140))),
        ],
      ),
    );
  }
}
