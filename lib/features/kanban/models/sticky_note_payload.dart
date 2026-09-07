class StickyNotePayload {
  final String id;
  final String title;
  final List<Map<String, dynamic>> items;
  final bool isFirst;
  final bool isLast;
  final String themeMode;
  final int seedColor;

  const StickyNotePayload({
    required this.id,
    required this.title,
    required this.items,
    this.isFirst = false,
    this.isLast = false,
    this.themeMode = 'system',
    this.seedColor = 0xFF2196F3, // Default Colors.blue
  });

  /// Converts the payload into a Map for IPC transmission
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'items': items,
      'isFirst': isFirst,
      'isLast': isLast,
      'themeMode': themeMode,
      'seedColor': seedColor,
    };
  }

  /// Safely parses incoming IPC data, handling MethodChannel's strict type casting
  factory StickyNotePayload.fromMap(Map<dynamic, dynamic> map) {
    return StickyNotePayload(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      // Safe casting mechanism for nested maps
      items:
          (map['items'] as List?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          [],
      isFirst: map['isFirst'] ?? false,
      isLast: map['isLast'] ?? false,
      themeMode: map['themeMode'] ?? 'system',
      seedColor: map['seedColor'] ?? 0xFF2196F3,
    );
  }
}
