import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../../../models/ipc_event.dart';
import 'swipe_background.dart';

class StickyNoteWidgetContent extends StatefulWidget {
  const StickyNoteWidgetContent({
    super.key,
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
  State<StickyNoteWidgetContent> createState() =>
      _StickyNoteWidgetContentState();
}

class _StickyNoteWidgetContentState extends State<StickyNoteWidgetContent> {
  void _fireEvent(IpcEvent event) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod(event.name, event.arguments);
  }

  void _invokeTaskEdit(String oldTask, String newTask) {
    _fireEvent(EditTaskEvent(widget.title, oldTask, newTask));
  }

  Future<bool?> _promptDelete(BuildContext context, String task) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final cancelButton = TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        );

        final deleteButton = TextButton(
          onPressed: () {
            _fireEvent(DeleteTaskEvent(widget.title, task));
            Navigator.pop(context, true);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        );

        return AlertDialog(
          title: const Text('Delete Task?'),
          content: const Text(
            'This task is at the end of the board. Do you want to delete it?',
          ),
          actions: [cancelButton, deleteButton],
        );
      },
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
            background: SwipeBackground(
              color: widget.isLast ? Colors.redAccent : Colors.green,
              icon: widget.isLast ? Icons.delete : Icons.arrow_forward,
              alignment: .centerLeft,
              padding: const .only(left: 16),
            ),
            secondaryBackground: SwipeBackground(
              color: widget.isFirst ? Colors.redAccent : Colors.blue,
              icon: widget.isFirst ? Icons.delete : Icons.arrow_back,
              alignment: .centerRight,
              padding: const .only(right: 16),
            ),
            confirmDismiss: (direction) async {
              if (direction == .startToEnd) {
                if (widget.isLast) {
                  return await _promptDelete(context, taskTitle);
                }
                _fireEvent(MoveNextEvent(widget.title, taskTitle));
                return true;
              } else {
                if (widget.isFirst) {
                  return await _promptDelete(context, taskTitle);
                }
                _fireEvent(MovePrevEvent(widget.title, taskTitle));
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
                    ? Image.asset(widget.imagePath!, fit: .cover)
                    : Image.file(File(widget.imagePath!), fit: .cover),
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
