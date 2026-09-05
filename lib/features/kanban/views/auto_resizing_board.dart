import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../models/kanban_task.dart';

class AutoResizingBoard extends StatelessWidget {
  const AutoResizingBoard({
    super.key,
    required this.categories,
    required this.onItemReorder,
    required this.onListReorder,
    required this.onPopOutCategory,
    required this.onAddTask,
    required this.onEditTask,
    required this.isProcessing,
    required this.processingGroupId,
  });

  final List<KanbanCategory> categories;
  final void Function(int, int, int, int) onItemReorder;
  final void Function(int, int) onListReorder;
  final Future<void> Function(KanbanCategory columnData) onPopOutCategory;
  final void Function(String groupId) onAddTask;
  final void Function(String groupId, KanbanTask task) onEditTask;
  final bool isProcessing;
  final String? processingGroupId;

  @override
  Widget build(BuildContext context) => Expanded(
    child: LayoutBuilder(
      builder: (_, constraints) {
        final numColumns = categories.length;
        if (numColumns == 0) return const SizedBox();

        final totalPadding = (numColumns + 1) * 16.0;
        final columnWidth = (constraints.maxWidth - totalPadding) / numColumns;

        final categoryList = categories.map(
          (category) => DragAndDropList(
            header: _HeaderWidget(
              columnData: category,
              processingGroupId: processingGroupId,
              isProcessing: isProcessing,
              onPopOutCategory: onPopOutCategory,
            ),
            footer: _AddTaskButton(onAddTask: () => onAddTask(category.id)),
            children: category.items
                .map(
                  (task) => DragAndDropItem(
                    child: _CardBuilder(
                      task: task,
                      groupId: category.id,
                      onEditTask: onEditTask,
                    ),
                  ),
                )
                .toList(),
          ),
        );

        return DragAndDropLists(
          horizontalAlignment: .center,
          verticalAlignment: .center,
          children: categoryList.toList(),
          onItemReorder: onItemReorder,
          onListReorder: onListReorder,
          axis: .horizontal,
          listWidth: columnWidth,
          listDraggingWidth: columnWidth,
          listPadding: const .symmetric(horizontal: 8),
          itemDecorationWhileDragging: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CardBuilder extends StatelessWidget {
  const _CardBuilder({
    required this.task,
    required this.groupId,
    required this.onEditTask,
  });

  final KanbanTask task;
  final String groupId;
  final void Function(String groupId, KanbanTask task) onEditTask;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTap: () => onEditTask(groupId, task),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const .only(bottom: 12, left: 8, right: 8),
      padding: const .all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: Text(task.title, textAlign: .left),
      ),
    ),
  );
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onAddTask,
    child: Padding(
      padding: const .all(16.0),
      child: Row(
        children: [
          Icon(Icons.add, size: 20, color: Colors.black.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            'New Task',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
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
  });

  final KanbanCategory columnData;
  final String? processingGroupId;
  final bool isProcessing;
  final Future<void> Function(KanbanCategory columnData) onPopOutCategory;

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = const Padding(
      padding: .all(8.0),
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      ),
    );

    final toggleButton = IconButton(
      onPressed: isProcessing ? null : () => onPopOutCategory(columnData),
      icon: Icon(
        Icons.open_in_new,
        size: 18,
        color: isProcessing ? Colors.grey.withValues(alpha: 0.4) : Colors.grey,
      ),
      tooltip: "Toggle sticky note",
    );

    return Container(
      height: 50,
      margin: const .symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: .circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.circle, size: 12, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              columnData.name,
              style: const TextStyle(fontWeight: .w600),
            ),
          ),
          processingGroupId == columnData.id ? loadingIndicator : toggleButton,
        ],
      ),
    );
  }
}
