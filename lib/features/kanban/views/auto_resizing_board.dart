import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../models/kanban_task.dart';

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
  final void Function(String groupId) onAddTask;
  final void Function(String groupId, KanbanTask task) onEditTask;
  final void Function(String groupId, KanbanTask task) onDeleteTask;
  final void Function(String groupId, String currentName) onEditCategory;
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
        header: _HeaderWidget(
          columnData: category,
          processingGroupId: widget.processingGroupId,
          isProcessing: widget.isProcessing,
          onPopOutCategory: widget.onPopOutCategory,
          onEditCategory: widget.onEditCategory,
          onDeleteCategory: widget.onDeleteCategory,
          onColumnResize: widget.onColumnResize,
          colorScheme: colorScheme,
        ),
        footer: _AddTaskButton(
          onAddTask: () => widget.onAddTask(category.id),
          colorScheme: colorScheme,
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

class _CardBuilder extends StatelessWidget {
  const _CardBuilder({
    required this.task,
    required this.groupId,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.colorScheme,
  });

  final KanbanTask task;
  final String groupId;
  final void Function(String groupId, KanbanTask task) onEditTask;
  final void Function(String groupId, KanbanTask task) onDeleteTask;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(bottom: 12, left: 8, right: 8),
    child: Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: .horizontal,

      // Swipe Right: Edit
      background: _SwipeBackground(
        color: Colors.blue,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
        padding: const .only(left: 20),
      ),

      // Swipe Left: Delete
      secondaryBackground: _SwipeBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: .centerRight,
        padding: const .only(right: 20),
      ),

      confirmDismiss: (direction) async {
        if (direction == .startToEnd) {
          // Edit gesture
          onEditTask(groupId, task);
          return false;
        } else {
          // Delete gesture
          onDeleteTask(groupId, task);
          return false;
        }
      },
      child: GestureDetector(
        onDoubleTap: () => onEditTask(groupId, task),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: .circular(8),
            border: .all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
            child: Text(
              task.title,
              textAlign: .left,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ),
      ),
    ),
  );
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

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onAddTask, required this.colorScheme});

  final VoidCallback onAddTask;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onAddTask,
    child: Padding(
      padding: const .all(16.0),
      child: Row(
        children: [
          Icon(Icons.add, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'New Task',
            style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6)),
          ),
        ],
      ),
    ),
  );
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({
    required this.columnData,
    required this.processingGroupId,
    required this.isProcessing,
    required this.onPopOutCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onColumnResize,
    required this.colorScheme,
  });

  final KanbanCategory columnData;
  final String? processingGroupId;
  final bool isProcessing;
  final Future<void> Function(KanbanCategory columnData) onPopOutCategory;
  final void Function(String groupId, String currentName) onEditCategory;
  final void Function(String groupId) onDeleteCategory;
  final void Function(double delta) onColumnResize;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = Padding(
      padding: .all(8.0),
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final toggleButton = IconButton(
      onPressed: isProcessing ? null : () => onPopOutCategory(columnData),
      icon: Icon(
        Icons.open_in_new,
        size: 18,
        color: isProcessing
            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
            : colorScheme.onSurfaceVariant,
      ),
      tooltip: "Toggle sticky note",
    );

    final popupMenuButton = PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      tooltip: "Category Options",
      onSelected: (value) {
        if (value == 'edit') {
          onEditCategory(columnData.id, columnData.name);
        } else if (value == 'delete') {
          onDeleteCategory(columnData.id);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Rename Category')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete Category', style: TextStyle(color: Colors.red)),
        ),
      ],
    );

    final dragHandle = MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: .opaque,
        onHorizontalDragDown: (_) {},
        onHorizontalDragStart: (_) {},
        onHorizontalDragUpdate: (details) => onColumnResize(details.delta.dx),
        child: Container(
          width: 16,
          color: Colors.transparent,
          child: Center(
            child: VerticalDivider(
              width: 2,
              thickness: 2,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              indent: 14,
              endIndent: 14,
            ),
          ),
        ),
      ),
    );

    return Container(
      height: 50,
      margin: const .symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: const .vertical(top: .circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.circle, size: 12, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              columnData.name,
              style: TextStyle(
                fontWeight: .w600,
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: .ellipsis,
            ),
          ),

          if (processingGroupId == columnData.id)
            loadingIndicator
          else
            toggleButton,

          popupMenuButton,
          dragHandle,
        ],
      ),
    );
  }
}
