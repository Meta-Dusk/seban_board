import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import '../models/kanban_task.dart';
import 'auto_resizing_board.dart';

class KanbanBoardPage extends StatefulWidget {
  const KanbanBoardPage({super.key});

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  final syncChannel = const WindowMethodChannel('kanban_sync');
  final Map<String, String> _activeCategoryWindows = {};
  bool _isWindowProcessing = false;
  String? _processingGroupId;

  List<KanbanCategory> categories = [];

  @override
  void initState() {
    super.initState();

    syncChannel.setMethodCallHandler((call) async {
      final payload = call.arguments as Map?;
      if (payload == null) return 'error';

      if (call.method == 'move_next') {
        _advanceTaskDirectionally(payload['category'], payload['task'], 1);
      } else if (call.method == 'move_prev') {
        _advanceTaskDirectionally(payload['category'], payload['task'], -1);
      } else if (call.method == 'delete_task') {
        _deleteTask(payload['category'], payload['task']);
      }
      return 'success';
    });

    categories = [
      KanbanCategory(
        id: 'todo',
        name: 'To Do',
        items: [
          KanbanTask('Design the "Twist"'),
          KanbanTask('Add Themes (Such as dark mode)'),
          KanbanTask('Add minimum size to all components'),
          KanbanTask('Editable Categories'),
          KanbanTask('Improve Title Bar'),
        ],
      ),
      KanbanCategory(
        id: 'progress',
        name: 'In Progress',
        items: [
          KanbanTask('Update Kanban Board Architecture'),
          KanbanTask('Clean Up Code'),
        ],
      ),
      KanbanCategory(
        id: 'done',
        name: 'Done',
        items: [
          KanbanTask('Kanban Board'),
          KanbanTask('Setup Multi-Window'),
          KanbanTask('Sticky Note Feature'),
          KanbanTask(
            'Fix animation for tasks being transferred (visual transition bug?)',
          ),
          KanbanTask(
            'Make tasks inside sticky notes be swipeable (transfer feature)',
          ),
        ],
      ),
    ];
  }

  void _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) {
    setState(() {
      final movedTask = categories[oldListIndex].items.removeAt(oldItemIndex);
      categories[newListIndex].items.insert(newItemIndex, movedTask);
    });

    _broadcastUpdate(categories[oldListIndex].id);
    if (oldListIndex != newListIndex) {
      _broadcastUpdate(categories[newListIndex].id);
    }
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      final movedList = categories.removeAt(oldListIndex);
      categories.insert(newListIndex, movedList);
    });
  }

  void _promptAddCategory() {
    _showInputDialog('New Category', (input) {
      final newGroupId = input.toLowerCase().replaceAll(' ', '_');
      setState(() {
        categories.add(KanbanCategory(id: newGroupId, name: input, items: []));
      });
    });
  }

  void _promptAddTask(String groupId) {
    _showInputDialog('New Task', (input) {
      final group = categories.firstWhere((g) => g.id == groupId);
      setState(() {
        group.items.add(KanbanTask(input));
      });
      _broadcastUpdate(groupId);
    });
  }

  void _promptEditTask(String groupId, KanbanTask oldTask) {
    _showInputDialog('Edit Task', (input) {
      final group = categories.firstWhere((g) => g.id == groupId);
      final index = group.items.indexWhere((t) => t.id == oldTask.id);
      if (index != -1) {
        setState(() {
          group.items[index] = KanbanTask(input);
        });
        _broadcastUpdate(groupId);
      }
    }, initialText: oldTask.title);
  }

  void _showInputDialog(
    String title,
    Function(String) onSubmit, {
    String initialText = '',
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String input = initialText;
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: initialText,
            autofocus: true,
            onChanged: (val) => input = val,
            onFieldSubmitted: (val) {
              if (val.isNotEmpty) onSubmit(val);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (input.isNotEmpty) onSubmit(input);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _advanceTaskDirectionally(
    String categoryName,
    String taskTitle,
    int direction,
  ) {
    final groupIndex = categories.indexWhere((g) => g.name == categoryName);
    if (groupIndex == -1) return;

    final targetIndex = groupIndex + direction;
    if (targetIndex < 0 || targetIndex >= categories.length) return;

    final currentGroup = categories[groupIndex];
    final targetGroup = categories[targetIndex];

    final taskIndex = currentGroup.items.indexWhere(
      (t) => t.title == taskTitle,
    );
    if (taskIndex != -1) {
      setState(() {
        final taskItem = currentGroup.items.removeAt(taskIndex);
        targetGroup.items.add(taskItem);
      });
      _broadcastUpdate(currentGroup.id);
      _broadcastUpdate(targetGroup.id);
    }
  }

  void _deleteTask(String categoryName, String taskTitle) {
    final group = categories.firstWhere((g) => g.name == categoryName);
    setState(() {
      group.items.removeWhere((t) => t.title == taskTitle);
    });
    _broadcastUpdate(group.id);
  }

  Future<void> _handlePopOutCategory(KanbanCategory columnData) async {
    if (_isWindowProcessing) return;

    final groupId = columnData.id;
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    final group = categories[groupIndex];

    setState(() {
      _isWindowProcessing = true;
      _processingGroupId = groupId;
    });

    try {
      if (_activeCategoryWindows.containsKey(groupId)) {
        final windowIdStr = _activeCategoryWindows[groupId]!;
        final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');

        bool closeSuccess = false;
        try {
          await uniqueChannel.invokeMethod('close_window');
          closeSuccess = true;
        } catch (_) {
          debugPrint('Window was already dead.');
        }

        _activeCategoryWindows.remove(groupId);
        if (closeSuccess) return;
      }

      final payload = jsonEncode({
        'title': group.name,
        'items': group.items.map((item) => item.title).toList(),
        'isFirst': groupIndex == 0,
        'isLast': groupIndex == categories.length - 1,
      });

      final window = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: payload),
      );

      final windowId = window.windowId;
      _activeCategoryWindows[groupId] = windowId.toString();

      final uniqueChannel = WindowMethodChannel('kanban_sync_$windowId');
      uniqueChannel.setMethodCallHandler((call) async {
        final payload = call.arguments as Map?;
        if (payload == null) return 'error';

        if (call.method == 'move_next') {
          _advanceTaskDirectionally(payload['category'], payload['task'], 1);
        } else if (call.method == 'move_prev') {
          _advanceTaskDirectionally(payload['category'], payload['task'], -1);
        } else if (call.method == 'delete_task') {
          _deleteTask(payload['category'], payload['task']);
        }
        return 'success';
      });
    } finally {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        setState(() {
          _isWindowProcessing = false;
          _processingGroupId = null;
        });
      }
    }
  }

  void _broadcastUpdate(String groupId) async {
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;
    final group = categories[groupIndex];

    final payload = {
      'title': group.name,
      'items': group.items.map((item) => item.title).toList(),
      'isFirst': groupIndex == 0,
      'isLast': groupIndex == categories.length - 1,
    };

    for (final windowIdStr in _activeCategoryWindows.values) {
      try {
        final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');
        await uniqueChannel.invokeMethod('update_category', payload);
      } catch (e) {
        debugPrint('Sticky note $windowIdStr not listening: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      mainAxisAlignment: .center,
      children: [
        CustomTitleBar(onAddCategory: _promptAddCategory),
        AutoResizingBoard(
          categories: categories,
          onItemReorder: _onItemReorder,
          onListReorder: _onListReorder,
          onPopOutCategory: _handlePopOutCategory,
          onAddTask: _promptAddTask,
          onEditTask: _promptEditTask,
          isProcessing: _isWindowProcessing,
          processingGroupId: _processingGroupId,
        ),
      ],
    ),
  );
}

class CustomTitleBar extends StatelessWidget {
  final VoidCallback onAddCategory;

  const CustomTitleBar({super.key, required this.onAddCategory});

  @override
  Widget build(BuildContext context) => DragToMoveArea(
    child: Container(
      height: 40,
      width: double.infinity,
      color: Colors.grey.withValues(alpha: 0.1),
      alignment: Alignment.centerLeft,
      padding: const .symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          const Text(
            'Seban Board',
            style: TextStyle(fontWeight: .bold, color: Colors.black87),
          ),
          IconButton(
            onPressed: onAddCategory,
            icon: const Icon(Icons.add_box, size: 18, color: Colors.black54),
            tooltip: "Add Category",
            padding: .zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ),
  );
}
