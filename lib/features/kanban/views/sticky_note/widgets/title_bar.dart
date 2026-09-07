import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../components/seed_color_selector.dart';

class DraggableStickyNoteTitleBar extends StatefulWidget {
  const DraggableStickyNoteTitleBar({
    super.key,
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
  State<DraggableStickyNoteTitleBar> createState() =>
      _DraggableStickyNoteTitleBarState();
}

class _DraggableStickyNoteTitleBarState
    extends State<DraggableStickyNoteTitleBar> {
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
  void didUpdateWidget(covariant DraggableStickyNoteTitleBar oldWidget) {
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
