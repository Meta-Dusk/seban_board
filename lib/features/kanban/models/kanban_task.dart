class KanbanTask {
  final String title;
  KanbanTask(this.title);
  String get id => title;
}

class KanbanCategory {
  final String id;
  final String name;
  final List<KanbanTask> items;

  KanbanCategory({required this.id, required this.name, required this.items});
}
