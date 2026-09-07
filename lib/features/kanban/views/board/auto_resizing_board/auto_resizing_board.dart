import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

import 'widgets/add_task_button.dart';
import 'widgets/card_builder.dart';
import 'widgets/visibility_fader.dart';
import 'widgets/header_widget.dart';
import '../../../models/kanban.dart';

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
    required this.onDeleteTaskPrompt,
    required this.onTaskDismissed,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.exitingGroupId,
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
  final Future<bool> Function(String groupId, KanbanTask task)
  onDeleteTaskPrompt;
  final void Function(String groupId, KanbanTask task) onTaskDismissed;
  final void Function(String groupId, String newName) onEditCategory;
  final void Function(String groupId) onDeleteCategory;
  final String? exitingGroupId;
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

    if (widget.categories.isEmpty) {
      return Expanded(
        child: Scrollbar(
          controller: _scrollController,
          thickness: 8.0,
          radius: const .circular(8),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: .horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              // Forces the scroll view to stretch across the screen
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                "No categories yet. Click the '+' icon to add one!",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: .w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final categoryList = widget.categories.map((category) {
      final bool isExiting = category.id == widget.exitingGroupId;

      final categoryItemsList = category.items.map(
        (task) => DragAndDropItem(
          child: VisibilityFader(
            isVisible: !isExiting,
            child: CardBuilder(
              task: task,
              groupId: category.id,
              onEditTask: widget.onEditTask,
              onDeleteTaskPrompt: widget.onDeleteTaskPrompt,
              onTaskDismissed: widget.onTaskDismissed,
              colorScheme: colorScheme,
            ),
          ),
        ),
      );

      return DragAndDropList(
        header: VisibilityFader(
          isVisible: !isExiting,
          child: HeaderWidget(
            columnData: category,
            processingGroupId: widget.processingGroupId,
            isProcessing: widget.isProcessing,
            onPopOutCategory: widget.onPopOutCategory,
            onEditCategory: widget.onEditCategory,
            onDeleteCategory: widget.onDeleteCategory,
            onColumnResize: widget.onColumnResize,
            colorScheme: colorScheme,
          ),
        ),
        footer: VisibilityFader(
          isVisible: !isExiting,
          child: AddTaskButton(
            onAddTask: (title) => widget.onAddTask(category.id, title),
            colorScheme: colorScheme,
          ),
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
