import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:seban_board/features/kanban/views/auto_resizing_board/header_widget.dart';
import '../../models/kanban_task.dart';

class AutoResizingBoard extends StatefulWidget {
  const AutoResizingBoard({
    super.key,
    required this.categories,
    required this.columnWidth,
    required this.onColumnResize,
    required this.onItemReorder,
    required this.onListReorder,
    required this.onPopOutCategory,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.isProcessing,
    required this.processingGroupId,
  });

  final List<KanbanCategory> categories;
  final double columnWidth;
  final void Function(double delta) onColumnResize;
  final void Function(int, int, int, int) onItemReorder;
  final void Function(int, int) onListReorder;
  final Future<void> Function(KanbanCategory columnData) onPopOutCategory;
  final void Function(String groupId, String taskTitle) onAddTask;
  final void Function(String groupId, KanbanTask task, String newTitle)
  onEditTask;
  final void Function(String groupId, KanbanTask task) onDeleteTask;
  final void Function(String groupId, String newName) onEditCategory;
  final void Function(String groupId) onDeleteCategory;
  final bool isProcessing;
  final String? processingGroupId;

  @override
  State<AutoResizingBoard> createState() => _AutoResizingBoardState();
}

class _AutoResizingBoardState extends State<AutoResizingBoard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final categoryList = widget.categories.map((category) {
      final categoryItemsList = category.items.map(
        (task) => DragAndDropItem(
          child: _CardBuilder(
            task: task,
            groupId: category.id,
            onEditTask: widget.onEditTask,
            onDeleteTask: widget.onDeleteTask,
            colorScheme: colorScheme,
          ),
        ),
      );

      return DragAndDropList(
        header: HeaderWidget(
          columnData: category,
          processingGroupId: widget.processingGroupId,
          isProcessing: widget.isProcessing,
          onPopOutCategory: widget.onPopOutCategory,
          onEditCategory: widget.onEditCategory,
          onDeleteCategory: widget.onDeleteCategory,
          onColumnResize: widget.onColumnResize,
          colorScheme: colorScheme,
        ),
        footer: AddTaskButton(
          onAddTask: (title) => widget.onAddTask(category.id, title),
        ),
        children: categoryItemsList.toList(),
      );
    });

    final dragAndDropLists = DragAndDropLists(
      children: categoryList.toList(),
      scrollController: _scrollController,
      onItemReorder: widget.onItemReorder,
      onListReorder: widget.onListReorder,
      axis: .horizontal,
      listWidth: widget.columnWidth,
      listDraggingWidth: widget.columnWidth,
      listPadding: const .symmetric(horizontal: 8),
      itemDragOnLongPress: false,
      listDragOnLongPress: false,
      listDecorationWhileDragging: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      itemDecorationWhileDragging: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final scrollbar = Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 8.0,
      radius: const .circular(8),
      child: Padding(
        padding: const .only(bottom: 12.0),
        child: dragAndDropLists,
      ),
    );

    return Expanded(
      child: widget.categories.isEmpty ? const SizedBox() : scrollbar,
    );
  }
}

class _CardBuilder extends StatefulWidget {
  const _CardBuilder({
    required this.task,
    required this.groupId,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.colorScheme,
  });

  final KanbanTask task;
  final String groupId;
  final void Function(String groupId, KanbanTask task, String newTitle)
  onEditTask;
  final void Function(String groupId, KanbanTask task) onDeleteTask;
  final ColorScheme colorScheme;

  @override
  State<_CardBuilder> createState() => _CardBuilderState();
}

class _CardBuilderState extends State<_CardBuilder> {
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
  void didUpdateWidget(covariant _CardBuilder oldWidget) {
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

    return Padding(
      padding: const .only(bottom: 12, left: 8, right: 8),
      child: Dismissible(
        key: ValueKey('dismiss_${widget.task.id}'),
        direction: .horizontal,
        background: const _SwipeBackground(
          color: Colors.blue,
          icon: Icons.edit,
          alignment: .centerLeft,
          padding: .only(left: 20),
        ),
        secondaryBackground: const _SwipeBackground(
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
            widget.onDeleteTask(widget.groupId, widget.task);
            return false;
          }
        },
        child: GestureDetector(
          onDoubleTap: () {
            setState(() => _isEditing = true);
            _focusNode.requestFocus();
          },
          child: Container(
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
            padding: const .all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: _isEditing ? textField : text,
            ),
          ),
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
    decoration: BoxDecoration(color: color, borderRadius: .circular(8)),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}

class AddTaskButton extends StatefulWidget {
  const AddTaskButton({super.key, required this.onAddTask});

  final void Function(String title) onAddTask;

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
    final colorScheme = Theme.of(context).colorScheme;

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
