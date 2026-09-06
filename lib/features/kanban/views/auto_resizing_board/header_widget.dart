import 'package:flutter/material.dart';
import 'package:seban_board/features/kanban/models/kanban_task.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({
    super.key,
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
  final void Function(String groupId, String newName) onEditCategory;
  final void Function(String groupId) onDeleteCategory;
  final void Function(double delta) onColumnResize;
  final ColorScheme colorScheme;

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.columnData.name);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
  }

  @override
  void didUpdateWidget(covariant HeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the main board's data changed in the background, update the controller
    if (oldWidget.columnData.name != widget.columnData.name && !_isEditing) {
      _controller.text = widget.columnData.name;
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
    widget.onEditCategory(widget.columnData.id, _controller.text);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: TextStyle(
        fontWeight: .w600,
        color: widget.colorScheme.onSurfaceVariant,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: .zero,
        border: .none,
      ),
      onSubmitted: (_) => _saveAndClose(),
    );

    final text = Text(
      widget.columnData.name,
      style: TextStyle(
        fontWeight: .w600,
        color: widget.colorScheme.onSurfaceVariant,
      ),
      overflow: .ellipsis,
    );

    final loadingIndicator = Padding(
      padding: const .all(8.0),
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final toggleButton = IconButton(
      onPressed: widget.isProcessing
          ? null
          : () => widget.onPopOutCategory(widget.columnData),
      icon: Icon(
        Icons.open_in_new,
        size: 18,
        color: widget.isProcessing
            ? widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
            : widget.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Toggle sticky note",
    );

    final popupMenuButton = PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: widget.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Category Options",
      onSelected: (value) {
        if (value == 'edit') {
          setState(() => _isEditing = true);
          _focusNode.requestFocus();
        } else if (value == 'delete') {
          widget.onDeleteCategory(widget.columnData.id);
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

    final mouseRegion = MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: .opaque,
        onHorizontalDragDown: (_) {},
        onHorizontalDragStart: (_) {},
        onHorizontalDragUpdate: (details) =>
            widget.onColumnResize(details.delta.dx),
        child: Container(
          width: 16,
          color: Colors.transparent,
          child: Center(
            child: VerticalDivider(
              width: 2,
              thickness: 2,
              color: widget.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
        color: widget.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.05,
        ),
        borderRadius: const .vertical(top: .circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.circle, size: 12, color: widget.colorScheme.primary),
          const SizedBox(width: 8),

          Expanded(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() => _isEditing = true);
                _focusNode.requestFocus();
              },
              child: _isEditing ? textField : text,
            ),
          ),

          if (widget.processingGroupId == widget.columnData.id)
            loadingIndicator
          else
            toggleButton,

          popupMenuButton,
          mouseRegion,
        ],
      ),
    );
  }
}
