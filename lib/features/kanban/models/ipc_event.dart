sealed class IpcEvent {
  const IpcEvent();

  /// Deserializes raw IPC data into a strongly typed event
  factory IpcEvent.fromCall(String method, Map<dynamic, dynamic>? payload) {
    final p = payload ?? {};
    switch (method) {
      case 'move_next':
        return MoveNextEvent(p['category'], p['task']);
      case 'move_prev':
        return MovePrevEvent(p['category'], p['task']);
      case 'delete_task':
        return DeleteTaskEvent(p['category'], p['task']);
      case 'edit_task':
        return EditTaskEvent(p['category'], p['oldTask'], p['newTask']);
      case 'rename_category':
        return RenameCategoryEvent(p['newName']);
      case 'delete_category':
        return const DeleteCategoryEvent();
      case 'close_window':
        return const CloseWindowEvent();
      case 'update_category':
        return UpdateCategoryEvent(p);
      default:
        throw UnimplementedError('Unknown IPC method: $method');
    }
  }

  /// The method string used by MethodChannel
  String get name;

  /// The payload map used by MethodChannel
  Map<String, dynamic>? get arguments => null;
}

// --- Event Dataclasses ---

class MoveNextEvent extends IpcEvent {
  final String category;
  final String task;
  const MoveNextEvent(this.category, this.task);

  @override
  String get name => 'move_next';
  @override
  Map<String, dynamic> get arguments => {'category': category, 'task': task};
}

class MovePrevEvent extends IpcEvent {
  final String category;
  final String task;
  const MovePrevEvent(this.category, this.task);

  @override
  String get name => 'move_prev';
  @override
  Map<String, dynamic> get arguments => {'category': category, 'task': task};
}

class DeleteTaskEvent extends IpcEvent {
  final String category;
  final String task;
  const DeleteTaskEvent(this.category, this.task);

  @override
  String get name => 'delete_task';
  @override
  Map<String, dynamic> get arguments => {'category': category, 'task': task};
}

class EditTaskEvent extends IpcEvent {
  final String category;
  final String oldTask;
  final String newTask;
  const EditTaskEvent(this.category, this.oldTask, this.newTask);

  @override
  String get name => 'edit_task';
  @override
  Map<String, dynamic> get arguments => {
    'category': category,
    'oldTask': oldTask,
    'newTask': newTask,
  };
}

class RenameCategoryEvent extends IpcEvent {
  final String newName;
  const RenameCategoryEvent(this.newName);

  @override
  String get name => 'rename_category';
  @override
  Map<String, dynamic> get arguments => {'newName': newName};
}

class DeleteCategoryEvent extends IpcEvent {
  const DeleteCategoryEvent();
  @override
  String get name => 'delete_category';
}

class CloseWindowEvent extends IpcEvent {
  const CloseWindowEvent();
  @override
  String get name => 'close_window';
}

class UpdateCategoryEvent extends IpcEvent {
  final Map<dynamic, dynamic> payload;
  const UpdateCategoryEvent(this.payload);

  @override
  String get name => 'update_category';
  @override
  Map<String, dynamic>? get arguments => Map<String, dynamic>.from(payload);
}
