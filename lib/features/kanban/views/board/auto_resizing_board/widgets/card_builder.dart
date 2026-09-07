import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../models/kanban.dart';
import 'swipe_background.dart';

class CardBuilder extends StatefulWidget {
  const CardBuilder({
    super.key,
    required this.task,
    required this.groupId,
    required this.onEditTask,
    required this.onDeleteTaskPrompt,
    required this.onTaskDismissed,
    required this.colorScheme,
  });

  final KanbanTask task;
  final String groupId;
  final void Function(String groupId, KanbanTask task, String newTitle)
  onEditTask;
  final Future<bool> Function(String groupId, KanbanTask task)
  onDeleteTaskPrompt;
  final void Function(String groupId, KanbanTask task) onTaskDismissed;
  final ColorScheme colorScheme;

  @override
  State<CardBuilder> createState() => _CardBuilderState();
}

class _CardBuilderState extends State<CardBuilder> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      // Auto-save if the user clicks away from the text field
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
  }

  @override
  void didUpdateWidget(covariant CardBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the main board's data changed in the background, update the controller
    if (oldWidget.task.title != widget.task.title && !_isEditing) {
      _controller.text = widget.task.title;
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
    widget.onEditTask(widget.groupId, widget.task, _controller.text);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 14),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: .zero,
        border: .none,
      ),
      onSubmitted: (_) => _saveAndClose(),
    );

    final text = Text(
      widget.task.title,
      textAlign: .left,
      style: TextStyle(color: widget.colorScheme.onSurface),
    );

    final mainContent = [
      if (widget.task.imagePath != null) ...[
        ClipRRect(
          borderRadius: .circular(4),
          child: widget.task.imagePath!.startsWith('assets/')
              ? Image.asset(widget.task.imagePath!, fit: .cover)
              : Image.file(File(widget.task.imagePath!), fit: .cover),
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(width: double.infinity, child: _isEditing ? textField : text),
    ];

    final cardContainer = Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainer,
        border: .all(
          color: widget.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: mainContent,
      ),
    );

    return Padding(
      padding: const .only(bottom: 12, left: 8, right: 8),
      child: Dismissible(
        key: ValueKey('dismiss_${widget.task.id}'),
        direction: .horizontal,
        background: const SwipeBackground(
          color: Colors.blue,
          icon: Icons.edit,
          alignment: .centerLeft,
          padding: .only(left: 20),
        ),
        secondaryBackground: const SwipeBackground(
          color: Colors.redAccent,
          icon: Icons.delete,
          alignment: .centerRight,
          padding: .only(right: 20),
        ),
        confirmDismiss: (direction) async {
          if (direction == .startToEnd) {
            setState(() => _isEditing = true);
            _focusNode.requestFocus();
            return false;
          } else {
            return await widget.onDeleteTaskPrompt(widget.groupId, widget.task);
          }
        },
        onDismissed: (direction) {
          widget.onTaskDismissed(widget.groupId, widget.task);
        },
        child: GestureDetector(
          onDoubleTap: () {
            setState(() => _isEditing = true);
            _focusNode.requestFocus();
          },
          child: cardContainer,
        ),
      ),
    );
  }
}
