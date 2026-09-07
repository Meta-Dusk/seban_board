class KanbanTask {
  final String title;
  final String? imagePath;

  const KanbanTask(this.title, {this.imagePath});

  String get id => title;

  Map<String, dynamic> toJson() => {
    'title': title,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory KanbanTask.fromJson(Map<String, dynamic> json) => KanbanTask(
    json['title'] as String,
    imagePath: json['imagePath'] as String?,
  );
}

class KanbanCategory {
  final String id;
  final String name;
  final List<KanbanTask> items;

  KanbanCategory({required this.id, required this.name, required this.items});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory KanbanCategory.fromJson(Map<String, dynamic> json) => KanbanCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>)
        .map((item) => KanbanTask.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
