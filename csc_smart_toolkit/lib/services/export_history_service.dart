import 'database_service.dart';

/// High-level API for the export_history table.
///
/// Records every PNG/JPG/PDF/ZIP export so users can review what they
/// have generated. Works alongside [ExportService] — callers should invoke
/// [record] after a successful export.
class ExportHistoryService {
  ExportHistoryService._();

  /// Record a completed export event.
  static Future<void> record({
    required String toolId,
    required String toolName,
    required String format,   // 'png' | 'jpg' | 'pdf' | 'zip'
    required String filePath,
    int fileSize = 0,
  }) async {
    await DatabaseService.insertExportHistory(
      toolId: toolId,
      toolName: toolName,
      format: format,
      filePath: filePath,
      fileSize: fileSize,
    );
  }

  /// Return all export events, newest first.
  static Future<List<ExportHistoryEntry>> getAll({int limit = 100}) async {
    final rows = await DatabaseService.getExportHistory(limit: limit);
    return rows.map(ExportHistoryEntry.fromMap).toList();
  }

  /// Wipe all export history.
  static Future<void> clear() => DatabaseService.clearExportHistory();
}

/// Data class for a single export record.
class ExportHistoryEntry {
  const ExportHistoryEntry({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.format,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
  });

  final int id;
  final String toolId;
  final String toolName;
  final String format;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;

  factory ExportHistoryEntry.fromMap(Map<String, dynamic> m) =>
      ExportHistoryEntry(
        id:        m['id'] as int,
        toolId:    m['tool_id'] as String,
        toolName:  m['tool_name'] as String,
        format:    m['format'] as String,
        filePath:  m['file_path'] as String,
        fileSize:  (m['file_size'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  String get fileName => filePath.split('/').last;

  String get formattedSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
