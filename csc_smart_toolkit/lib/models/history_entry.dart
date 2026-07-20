import 'dart:convert';

/// One recorded usage of a tool.
class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.category,
    required this.timestamp,
  });

  final String id;
  final String toolId;
  final String toolName;
  final String category;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'toolName': toolName,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        toolName: json['toolName'] as String,
        category: json['category'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  static List<HistoryEntry> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<HistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());
}
