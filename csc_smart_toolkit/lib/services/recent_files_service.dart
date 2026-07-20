import 'database_service.dart';

/// High-level API for the recent_files table.
///
/// Tracks files recently exported, downloaded, or opened by the user so
/// they can quickly re-share or re-open them from the History screen.
class RecentFilesService {
  RecentFilesService._();

  /// Add or bump a file to the top of the recent list.
  static Future<void> add({
    required String filePath,
    required String fileName,
    required String fileType,  // 'png' | 'jpg' | 'pdf' | 'zip' | etc.
    String toolId = '',
  }) async {
    await DatabaseService.insertRecentFile(
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
      toolId: toolId,
    );
  }

  /// Return the most recently used files (newest first, max [limit]).
  static Future<List<RecentFileEntry>> getAll({int limit = 20}) async {
    final rows = await DatabaseService.getRecentFiles(limit: limit);
    return rows.map(RecentFileEntry.fromMap).toList();
  }

  /// Remove all recent file records.
  static Future<void> clear() => DatabaseService.clearRecentFiles();
}

/// Data class for one recent file record.
class RecentFileEntry {
  const RecentFileEntry({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.toolId,
    required this.createdAt,
  });

  final int id;
  final String filePath;
  final String fileName;
  final String fileType;
  final String toolId;
  final DateTime createdAt;

  factory RecentFileEntry.fromMap(Map<String, dynamic> m) => RecentFileEntry(
        id:        m['id'] as int,
        filePath:  m['file_path'] as String,
        fileName:  m['file_name'] as String,
        fileType:  m['file_type'] as String,
        toolId:    (m['tool_id'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}
