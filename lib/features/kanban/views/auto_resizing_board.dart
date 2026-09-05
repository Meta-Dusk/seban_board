import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';

import '../models/kanban_task.dart';

typedef AsyncDynamicAppFlowyGroupFunc =
    Future<dynamic> Function(AppFlowyGroupData<dynamic> columnData);

class AutoResizingBoard extends StatelessWidget {
  const AutoResizingBoard({
    super.key,
    required this.controller,
    required this.onPopOutCategory,
    required this.onAddTask,
    required this.onEditTask,
    required this.isProcessing,
    required this.processingGroupId,
  });

  final AppFlowyBoardController controller;
  final Future<void> Function(AppFlowyGroupData columnData) onPopOutCategory;
  final void Function(String groupId) onAddTask;
  final void Function(String groupId, KanbanTask task) onEditTask;
  final bool isProcessing;
  final String? processingGroupId;

  @override
  Widget build(BuildContext context) => Expanded(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final numColumns = controller.groupIds.length;
        final totalPadding = (numColumns + 1) * 16.0;
        final columnWidth = (constraints.maxWidth - totalPadding) / numColumns;

        return AppFlowyBoard(
          controller: controller,
          groupConstraints: .tightFor(width: columnWidth),
          config: AppFlowyBoardConfig(
            groupBackgroundColor: Colors.grey.withValues(alpha: 0.05),
            stretchGroupHeight: true,
          ),
          headerBuilder: (_, columnData) => _HeaderWidget(
            columnData: columnData,
            processingGroupId: processingGroupId,
            isProcessing: isProcessing,
            onPopOutCategory: onPopOutCategory,
          ),
          cardBuilder: (_, group, groupItem) {
            final task = groupItem as KanbanTask;
            return _CardBuilder(
              key: ValueKey(task.id),
              task: task,
              groupId: group.id,
              onEditTask: onEditTask,
            );
          },
          footerBuilder: (_, columnData) =>
              _AddTaskButton(onAddTask: () => onAddTask(columnData.id)),
        );
      },
    ),
  );
}

class _CardBuilder extends StatelessWidget {
  const _CardBuilder({
    super.key,
    required this.task,
    required this.groupId,
    required this.onEditTask,
  });

  final KanbanTask task;
  final String groupId;
  final void Function(String groupId, KanbanTask task) onEditTask;

  @override
  Widget build(BuildContext context) => Align(
    alignment: .topCenter,
    child: GestureDetector(
      onDoubleTap: () => onEditTask(groupId, task),
      child: AppFlowyGroupCard(
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
        margin: const .only(bottom: 12, left: 16, right: 16),
        child: Padding(
          padding: const .all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Text(task.title, textAlign: .left),
          ),
        ),
      ),
    ),
  );
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Icon(Icons.add, size: 20, color: Colors.black.withValues(alpha: 0.6)),
      const SizedBox(width: 8),
      Text(
        'New Task',
        style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
      ),
    ];
    return InkWell(
      onTap: onAddTask,
      child: Padding(
        padding: const .all(16.0),
        child: Row(children: mainContent),
      ),
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({
    required this.columnData,
    required this.processingGroupId,
    required this.isProcessing,
    required this.onPopOutCategory,
  });

  final AppFlowyGroupData<dynamic> columnData;
  final String? processingGroupId;
  final bool isProcessing;
  final AsyncDynamicAppFlowyGroupFunc onPopOutCategory;

  @override
  Widget build(BuildContext context) => AppFlowyGroupHeader(
    icon: const Icon(Icons.circle, size: 12, color: Colors.blueAccent),
    title: Text(
      columnData.headerData.groupName,
      style: const TextStyle(fontWeight: .w600),
    ),
    height: 50,
    margin: const .symmetric(horizontal: 16),
    addIcon: processingGroupId == columnData.id
        ? const Padding(
            padding: .all(8.0),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
          )
        : IconButton(
            onPressed: isProcessing ? null : () => onPopOutCategory(columnData),
            icon: Icon(
              Icons.open_in_new,
              size: 18,
              color: isProcessing
                  ? Colors.grey.withValues(alpha: 0.4)
                  : Colors.grey,
            ),
            tooltip: "Toggle sticky note",
          ),
  );
}
