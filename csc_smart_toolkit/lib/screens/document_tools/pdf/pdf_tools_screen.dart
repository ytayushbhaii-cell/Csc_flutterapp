import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PDFToolsScreen extends StatelessWidget {
  const PDFToolsScreen({super.key});

  static const _tools = [
    _Entry('Merge PDF', Icons.call_merge_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/merge'),
    _Entry('Split PDF', Icons.call_split_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/split'),
    _Entry('Compress PDF', Icons.compress, Color(0xFFDC2626),
        '/document-tools/pdf/compress'),
    _Entry('Rotate PDF', Icons.rotate_right_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/rotate'),
    _Entry('Extract Pages', Icons.content_cut_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/extract'),
    _Entry('Delete Pages', Icons.delete_outline, Color(0xFFDC2626),
        '/document-tools/pdf/delete-pages'),
    _Entry('Image to PDF', Icons.image_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/from-image'),
    _Entry('PDF to Image', Icons.photo_outlined, Color(0xFFDC2626),
        '/document-tools/pdf/to-image'),
    _Entry('OCR (Offline)', Icons.document_scanner_outlined,
        Color(0xFFDC2626), '/document-tools/pdf/ocr'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Tools')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final t = _tools[i];
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
                    Text('PDF Tools',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(130))),
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

class _Entry {
  const _Entry(this.name, this.icon, this.color, this.route);
  final String name;
  final IconData icon;
  final Color color;
  final String route;
}
