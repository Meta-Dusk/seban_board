import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import '../models/sticky_note_payload.dart';
import '../models/kanban.dart';
import '../models/ipc_event.dart';

class WindowSyncService {
  // Keeps track of which category ID belongs to which Window ID
  final Map<String, String> _activeWindows = {};
  final WindowMethodChannel _mainChannel = const WindowMethodChannel(
    'kanban_sync',
  );

  /// Sets up the primary listener for actions that don't come from a specific sticky note
  void initMainListener({
    required void Function(String category, String task, int direction)
    onMoveTask,
    required void Function(String category, String task) onDeleteTask,
  }) {
    _mainChannel.setMethodCallHandler((call) async {
      final event = IpcEvent.fromCall(call.method, call.arguments as Map?);

      switch (event) {
        case MoveNextEvent():
          onMoveTask(event.category, event.task, 1);
        case MovePrevEvent():
          onMoveTask(event.category, event.task, -1);
        case DeleteTaskEvent():
          onDeleteTask(event.category, event.task);
        case _:
          break;
      }

      return 'success';
    });
  }

  /// Spawns a new sticky note window or closes it if it already exists
  Future<void> toggleStickyNote({
    required KanbanCategory group,
    required int groupIndex,
    required int totalGroups,
    required String themeModeName,
    required int seedColorValue,
    required void Function(String groupId, String newName) onRenameCategory,
    required void Function(String groupId) onDeleteCategory,
    required void Function(String category, String task, int direction)
    onMoveTask,
    required void Function(String category, String task) onDeleteTask,
    required void Function(String groupId, KanbanTask oldTask, String newTask)
    onEditTask,
  }) async {
    final groupId = group.id;

    // If it's already open, close it and remove from tracking
    if (_activeWindows.containsKey(groupId)) {
      final windowIdStr = _activeWindows[groupId]!;
      final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');
      try {
        final event = const CloseWindowEvent();
        await uniqueChannel.invokeMethod(event.name, event.arguments);
      } catch (_) {
        debugPrint('Window was already dead.');
      }
      _activeWindows.remove(groupId);
      return;
    }

    // If it's not open, prepare the payload
    final payloadObj = StickyNotePayload(
      id: group.id,
      title: group.name,
      items: group.items.map((item) => item.toJson()).toList(),
      isFirst: groupIndex == 0,
      isLast: groupIndex == totalGroups - 1,
      themeMode: themeModeName,
      seedColor: seedColorValue,
    );

    final payload = jsonEncode(payloadObj.toMap());

    // Spawn the window
    final window = await WindowController.create(
      WindowConfiguration(hiddenAtLaunch: true, arguments: payload),
    );

    final windowId = window.windowId;
    _activeWindows[groupId] = windowId.toString();

    // Bind the specific listener for this new window
    final uniqueChannel = WindowMethodChannel('kanban_sync_$windowId');
    uniqueChannel.setMethodCallHandler((call) async {
      final event = IpcEvent.fromCall(call.method, call.arguments as Map?);

      switch (event) {
        case MoveNextEvent():
          onMoveTask(event.category, event.task, 1);
        case MovePrevEvent():
          onMoveTask(event.category, event.task, -1);
        case DeleteTaskEvent():
          onDeleteTask(event.category, event.task);
        case RenameCategoryEvent():
          onRenameCategory(groupId, event.newName);
        case DeleteCategoryEvent():
          onDeleteCategory(groupId);
        case EditTaskEvent():
          onEditTask(groupId, KanbanTask(event.oldTask), event.newTask);
        case CloseWindowEvent():
        case UpdateCategoryEvent():
          break;
      }
      return 'success';
    });
  }

  /// Sends the latest data to a specific sticky note if it's currently open
  void broadcastUpdate({
    required KanbanCategory group,
    required int groupIndex,
    required int totalGroups,
    required String themeModeName,
    required int seedColorValue,
  }) async {
    final groupId = group.id;
    if (_activeWindows.containsKey(groupId)) {
      final windowIdStr = _activeWindows[groupId]!;
      final payloadObj = StickyNotePayload(
        id: group.id,
        title: group.name,
        items: group.items.map((item) => item.toJson()).toList(),
        isFirst: groupIndex == 0,
        isLast: groupIndex == totalGroups - 1,
        themeMode: themeModeName,
        seedColor: seedColorValue,
      );

      try {
        final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');
        final event = UpdateCategoryEvent(payloadObj.toMap());
        await uniqueChannel.invokeMethod(event.name, event.arguments);
      } catch (e) {
        debugPrint('Sticky note $windowIdStr not listening: $e');
      }
    }
  }

  /// Force-closes a specific window
  /// (used when a category is deleted from the main board)
  Future<void> closeWindow(String groupId) async {
    if (_activeWindows.containsKey(groupId)) {
      final windowIdStr = _activeWindows[groupId]!;
      final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');

      try {
        final event = const CloseWindowEvent();
        await uniqueChannel.invokeMethod(event.name, event.arguments);
      } catch (e) {
        debugPrint('Window was already dead: $e');
      }

      _activeWindows.remove(groupId);
    }
  }
}
