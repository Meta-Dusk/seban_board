import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:seban_board/components/seed_color_selector.dart';

class StickyNotePage extends StatefulWidget {
  final String windowId;
  final Map<String, dynamic> data;

  const StickyNotePage({super.key, required this.windowId, required this.data});

  @override
  State<StickyNotePage> createState() => _StickyNotePageState();
}

class _StickyNotePageState extends State<StickyNotePage> {
  late String groupId;
  late String title;
  late List<Map<String, dynamic>> items;
  late bool isFirst;
  late bool isLast;
  late ThemeMode themeMode;
  late Color localSeedColor;

  @override
  void initState() {
    super.initState();
    groupId = widget.data['id'] ?? '';
    title = widget.data['title'] ?? "Notes";
    items = List<Map<String, dynamic>>.from(widget.data['items'] ?? []);
    isFirst = widget.data['isFirst'] ?? false;
    isLast = widget.data['isLast'] ?? false;

    _applyThemeFromPayload(widget.data);

    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.setMethodCallHandler((call) async {
      if (call.method == 'close_window') {
        Future.delayed(const Duration(milliseconds: 50), () async {
          await windowManager.close();
        });
        return 'success';
      } else if (call.method == 'update_category' && call.arguments != null) {
        final payload = call.arguments as Map;
        setState(() {
          title = payload['title'];
          items = List<Map<String, dynamic>>.from(payload['items']);
          isFirst = payload['isFirst'] ?? false;
          isLast = payload['isLast'] ?? false;

          final updatedModeStr = payload['themeMode'] ?? 'system';
          themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == updatedModeStr,
            orElse: () => ThemeMode.system,
          );
        });
      }
      return 'success';
    });
  }

  void _applyThemeFromPayload(Map data) {
    final modeStr = data['themeMode'] ?? 'system';
    themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => .system,
    );

    final int incomingColorInt = data['seedColor'] ?? Colors.blue.toARGB32();

    const colorList = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    localSeedColor = colorList.firstWhere(
      (c) => c.toARGB32() == incomingColorInt,
      orElse: () => Colors.blue,
    );
  }

  void _submitRename(String newName) {
    if (newName.trim().isEmpty) return;
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod('rename_category', {'newName': newName});
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = themeMode == .system
        ? MediaQuery.platformBrightnessOf(context)
        : (themeMode == .dark ? .dark : .light);

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: localSeedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return AnimatedTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StickyNoteWidget(
          title: title,
          items: items,
          windowId: widget.windowId,
          isFirst: isFirst,
          isLast: isLast,
          currentColor: localSeedColor,
          onEditCategory: _submitRename,
          onColorChanged: (color) => setState(() => localSeedColor = color),
        ),
      ),
    );
  }
}

class StickyNoteWidget extends StatelessWidget {
  const StickyNoteWidget({
    super.key,
    required this.title,
    required this.items,
    required this.windowId,
    required this.isFirst,
    required this.isLast,
    required this.currentColor,
    required this.onEditCategory,
    required this.onColorChanged,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String windowId;
  final bool isFirst;
  final bool isLast;
  final Color currentColor;
  final void Function(String) onEditCategory;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.85),
        borderRadius: .circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _DraggableStickyNoteTitleBar(
            title: title,
            currentColor: currentColor,
            onEditCategory: onEditCategory,
            onColorChanged: onColorChanged,
          ),
          _StickyNoteWidgetContent(
            title: title,
            items: items,
            windowId: windowId,
            isFirst: isFirst,
            isLast: isLast,
          ),
        ],
      ),
    );
  }
}

class _StickyNoteWidgetContent extends StatefulWidget {
  const _StickyNoteWidgetContent({
    required this.title,
    required this.items,
    required this.windowId,
    required this.isFirst,
    required this.isLast,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String windowId;
  final bool isFirst;
  final bool isLast;

  @override
  State<_StickyNoteWidgetContent> createState() =>
      _StickyNoteWidgetContentState();
}

class _StickyNoteWidgetContentState extends State<_StickyNoteWidgetContent> {
  void _invokeTaskAction(String task, String action) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod(action, {
      'category': widget.title,
      'task': task,
    });
  }

  void _invokeTaskEdit(String oldTask, String newTask) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod('edit_task', {
      'category': widget.title,
      'oldTask': oldTask,
      'newTask': newTask,
    });
  }

  Future<bool?> _promptDelete(BuildContext context, String task) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'This task is at the end of the board. Do you want to delete it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _invokeTaskAction(task, 'delete_task');
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: ListView.builder(
        padding: const .all(12),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final taskData = widget.items[index];
          final taskTitle = taskData['title'];
          final taskImagePath = taskData['imagePath'] as String?;

          return Dismissible(
            key: ValueKey(taskTitle),
            direction: .horizontal,
            background: _SwipeBackground(
              color: widget.isLast ? Colors.redAccent : Colors.green,
              icon: widget.isLast ? Icons.delete : Icons.arrow_forward,
              alignment: .centerLeft,
              padding: const .only(left: 16),
            ),
            secondaryBackground: _SwipeBackground(
              color: widget.isFirst ? Colors.redAccent : Colors.blue,
              icon: widget.isFirst ? Icons.delete : Icons.arrow_back,
              alignment: .centerRight,
              padding: const .only(right: 16),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                if (widget.isLast) {
                  return await _promptDelete(context, taskTitle);
                }
                _invokeTaskAction(taskTitle, 'move_next');
                return true;
              } else {
                if (widget.isFirst) {
                  return await _promptDelete(context, taskTitle);
                }
                _invokeTaskAction(taskTitle, 'move_prev');
                return true;
              }
            },
            onDismissed: (direction) {
              setState(() => widget.items.removeAt(index));
            },
            child: _InlineTaskItem(
              taskTitle: taskTitle,
              imagePath: taskImagePath,
              colorScheme: colorScheme,
              onEditTask: _invokeTaskEdit,
            ),
          );
        },
      ),
    );
  }
}

class _InlineTaskItem extends StatefulWidget {
  final String taskTitle;
  final String? imagePath;
  final ColorScheme colorScheme;
  final void Function(String oldTask, String newTask) onEditTask;

  const _InlineTaskItem({
    required this.taskTitle,
    required this.imagePath,
    required this.colorScheme,
    required this.onEditTask,
  });

  @override
  State<_InlineTaskItem> createState() => _InlineTaskItemState();
}

class _InlineTaskItemState extends State<_InlineTaskItem> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.taskTitle);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
  }

  @override
  void didUpdateWidget(covariant _InlineTaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle background updates over the IPC channel
    if (oldWidget.taskTitle != widget.taskTitle && !_isEditing) {
      _controller.text = widget.taskTitle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    if (!_isEditing) return;
    final text = _controller.text.trim();
    if (text.isNotEmpty && text != widget.taskTitle) {
      widget.onEditTask(widget.taskTitle, text);
    } else {
      _controller.text = widget.taskTitle; // Revert if blank
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: TextStyle(
        color: widget.colorScheme.onPrimaryContainer,
        fontSize: 14,
        height: 1.3,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: .zero,
        border: .none,
      ),
      onSubmitted: (_) => _saveAndClose(),
    );

    final text = Text(
      widget.taskTitle,
      style: TextStyle(
        color: widget.colorScheme.onPrimaryContainer,
        fontSize: 14,
        height: 1.3,
      ),
    );

    return GestureDetector(
      onDoubleTap: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      child: Padding(
        padding: const .symmetric(vertical: 12.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            if (widget.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: widget.imagePath!.startsWith('assets/')
                    ? Image.asset(widget.imagePath!, fit: BoxFit.cover)
                    : Image.file(File(widget.imagePath!), fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: _isEditing ? textField : text,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.padding,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: padding,
    color: color,
    child: Icon(icon, color: Colors.white, size: 20),
  );
}

class _DraggableStickyNoteTitleBar extends StatefulWidget {
  const _DraggableStickyNoteTitleBar({
    required this.title,
    required this.currentColor,
    required this.onEditCategory,
    required this.onColorChanged,
  });

  final String title;
  final Color currentColor;
  final void Function(String) onEditCategory;
  final ValueChanged<Color> onColorChanged;

  @override
  State<_DraggableStickyNoteTitleBar> createState() =>
      _DraggableStickyNoteTitleBarState();
}

class _DraggableStickyNoteTitleBarState
    extends State<_DraggableStickyNoteTitleBar> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
  }

  @override
  void didUpdateWidget(covariant _DraggableStickyNoteTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && !_isEditing) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    if (!_isEditing) return;
    final text = _controller.text.trim();
    if (text.isNotEmpty && text != widget.title) {
      widget.onEditCategory(text);
    } else {
      _controller.text = widget.title;
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final colorSelector = SeedColorSelector(
      currentColor: widget.currentColor,
      onColorChanged: widget.onColorChanged,
    );

    final closeButton = IconButton(
      icon: Icon(Icons.close, size: 18, color: colorScheme.onPrimaryContainer),
      onPressed: () async => await windowManager.close(),
      constraints: const BoxConstraints(),
    );

    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: TextStyle(
        fontWeight: .bold,
        fontSize: 16,
        color: colorScheme.onPrimaryContainer,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: .zero,
        border: .none,
      ),
      onSubmitted: (_) => _saveAndClose(),
    );

    final text = Text(
      widget.title,
      style: TextStyle(
        fontWeight: .bold,
        fontSize: 16,
        color: colorScheme.onPrimaryContainer,
      ),
      overflow: .ellipsis,
    );

    return DragToMoveArea(
      child: Container(
        padding: const .only(left: 12, right: 4, top: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() => _isEditing = true);
                  _focusNode.requestFocus();
                },
                child: _isEditing ? textField : text,
              ),
            ),
            Row(
              mainAxisSize: .min,
              children: [colorSelector, closeButton, const SizedBox(width: 8)],
            ),
          ],
        ),
      ),
    );
  }
}
