import 'package:flutter/material.dart';

class AddTaskButton extends StatefulWidget {
  const AddTaskButton({
    super.key,
    required this.onAddTask,
    required this.colorScheme,
  });

  final void Function(String title) onAddTask;
  final ColorScheme colorScheme;

  @override
  State<AddTaskButton> createState() => _AddTaskButtonState();
}

class _AddTaskButtonState extends State<AddTaskButton> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
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
    if (text.isNotEmpty) {
      widget.onAddTask(text);
    }
    _controller.clear();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    if (_isEditing) {
      return Padding(
        padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter task title...',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            isDense: true,
            contentPadding: .zero,
            border: .none,
          ),
          onSubmitted: (_) => _saveAndClose(),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      child: Padding(
        padding: const .all(16.0),
        child: Row(
          children: [
            Icon(Icons.add, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'New Task',
              style: TextStyle(
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
