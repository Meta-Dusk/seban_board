import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';
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
  late AppFlowyBoardController controller;
  final syncChannel = const WindowMethodChannel('kanban_sync');

  // Track which category IDs are currently popped out
  final Map<String, String> _activeCategoryWindows = {};

  // Global lock to prevent concurrent engine spawning
  bool _isWindowProcessing = false;
  // Tracks which specific category gets the loading spinner
  String? _processingGroupId;

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

    final todoGroup = AppFlowyGroupData(
      id: 'todo',
      name: 'To Do',
      items: [KanbanTask('Design the "Twist"')],
    );

    final progressGroup = AppFlowyGroupData(
      id: 'progress',
      name: 'In Progress',
      items: [KanbanTask('Finish Sticky Note Popup Feature')],
    );

    final doneGroup = AppFlowyGroupData(
      id: 'done',
      name: 'Done',
      items: [
        KanbanTask('Auto-resizing columns UI'),
        KanbanTask('Setup Multi-Window'),
      ],
    );

    controller = AppFlowyBoardController(
      onMoveGroupItem: (groupId, fromIndex, toIndex) =>
          _broadcastUpdate(groupId),
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        _broadcastUpdate(fromGroupId);
        _broadcastUpdate(toGroupId);
      },
    );

    controller.addGroup(todoGroup);
    controller.addGroup(progressGroup);
    controller.addGroup(doneGroup);
  }

  // --- CRUD METHODS WITH DIALOGS ---

  void _promptAddCategory() {
    _showInputDialog('New Category', (input) {
      final newGroupId = input.toLowerCase().replaceAll(' ', '_');
      controller.addGroup(
        AppFlowyGroupData(id: newGroupId, name: input, items: []),
      );
      setState(() {});
    });
  }

  void _promptAddTask(String groupId) {
    _showInputDialog('New Task', (input) {
      controller.addGroupItem(groupId, KanbanTask(input));
      _broadcastUpdate(groupId);
    });
  }

  void _promptEditTask(String groupId, KanbanTask oldTask) {
    _showInputDialog('Edit Task', (input) {
      controller.removeGroupItem(groupId, oldTask.id);
      controller.addGroupItem(groupId, KanbanTask(input));
      _broadcastUpdate(groupId);
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

  // --- LOGIC METHODS ---

  void _advanceTaskDirectionally(
    String categoryName,
    String taskTitle,
    int direction,
  ) {
    final groupIndex = controller.groupDatas.indexWhere(
      (g) => g.headerData.groupName == categoryName,
    );
    if (groupIndex == -1) return;

    final targetIndex = groupIndex + direction;
    if (targetIndex < 0 || targetIndex >= controller.groupDatas.length) return;

    final currentGroup = controller.groupDatas[groupIndex];
    final targetGroup = controller.groupDatas[targetIndex];

    try {
      final taskItem = currentGroup.items.cast<KanbanTask>().firstWhere(
        (t) => t.title == taskTitle,
      );
      controller.removeGroupItem(currentGroup.id, taskItem.id);
      controller.addGroupItem(targetGroup.id, taskItem);

      _broadcastUpdate(currentGroup.id);
      _broadcastUpdate(targetGroup.id);
    } catch (e) {
      debugPrint('Task not found.');
    }
  }

  void _deleteTask(String categoryName, String taskTitle) {
    final group = controller.groupDatas.firstWhere(
      (g) => g.headerData.groupName == categoryName,
    );
    try {
      final taskItem = group.items.cast<KanbanTask>().firstWhere(
        (t) => t.title == taskTitle,
      );
      controller.removeGroupItem(group.id, taskItem.id);
      _broadcastUpdate(group.id);
    } catch (_) {}
  }

  Future<void> _handlePopOutCategory(AppFlowyGroupData columnData) async {
    if (_isWindowProcessing) return;

    final groupId = columnData.id;
    final groupIndex = controller.groupDatas.indexWhere((g) => g.id == groupId);
    final group = controller.groupDatas[groupIndex];

    setState(() {
      _isWindowProcessing = true;
      _processingGroupId = groupId;
    });

    try {
      // If it's already open, command the sub-window to close itself
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

      // Otherwise, spawn the new window
      final payload = jsonEncode({
        'title': group.headerData.groupName,
        'items': group.items.map((item) => (item as KanbanTask).title).toList(),
        'isFirst': groupIndex == 0,
        'isLast': groupIndex == controller.groupDatas.length - 1,
      });

      final window = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: payload),
      );

      final windowId = window.windowId;
      _activeCategoryWindows[groupId] = windowId.toString();

      // Create the dedicated pipe to listen for checkouts from this new window
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
    final groupIndex = controller.groupDatas.indexWhere((g) => g.id == groupId);
    final group = controller.groupDatas[groupIndex];

    final payload = {
      'title': group.headerData.groupName,
      'items': group.items.map((item) => (item as KanbanTask).title).toList(),
      'isFirst': groupIndex == 0,
      'isLast': groupIndex == controller.groupDatas.length - 1,
    };

    // Broadcast the update to ALL active unique channels
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
      children: [
        CustomTitleBar(onAddCategory: _promptAddCategory),
        AutoResizingBoard(
          controller: controller,
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
      alignment: .centerLeft,
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
