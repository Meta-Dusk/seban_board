import 'package:flutter/material.dart';
import 'package:seban_board/components/seed_color_selector.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class StickyNotePage extends StatefulWidget {
  final String windowId;
  final Map<String, dynamic> data;

  const StickyNotePage({super.key, required this.windowId, required this.data});

  @override
  State<StickyNotePage> createState() => _StickyNotePageState();
}

class _StickyNotePageState extends State<StickyNotePage> {
  late String groupId;
  late String title;
  late List<String> items;
  late bool isFirst;
  late bool isLast;
  late ThemeMode themeMode;
  late Color localSeedColor;

  @override
  void initState() {
    super.initState();
    groupId = widget.data['id'] ?? '';
    title = widget.data['title'] ?? "Notes";
    items = List<String>.from(widget.data['items'] ?? []);
    isFirst = widget.data['isFirst'] ?? false;
    isLast = widget.data['isLast'] ?? false;

    _applyThemeFromPayload(widget.data);

    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.setMethodCallHandler((call) async {
      if (call.method == 'close_window') {
        Future.delayed(const Duration(milliseconds: 50), () async {
          await windowManager.close();
        });
        return 'success';
      } else if (call.method == 'update_category' && call.arguments != null) {
        final payload = call.arguments as Map;
        setState(() {
          title = payload['title'];
          items = List<String>.from(payload['items']);
          isFirst = payload['isFirst'] ?? false;
          isLast = payload['isLast'] ?? false;

          final updatedModeStr = payload['themeMode'] ?? 'system';
          themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == updatedModeStr,
            orElse: () => .system,
          );
        });
      }
      return 'success';
    });
  }

  void _applyThemeFromPayload(Map data) {
    final modeStr = data['themeMode'] ?? 'system';
    themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => .system,
    );

    final int incomingColorInt = data['seedColor'] ?? Colors.blue.toARGB32();

    const colorList = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    localSeedColor = colorList.firstWhere(
      (c) => c.toARGB32() == incomingColorInt,
      orElse: () => Colors.blue,
    );
  }

  void _promptEditCategory() {
    String input = title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextFormField(
          initialValue: title,
          autofocus: true,
          onChanged: (val) => input = val,
          onFieldSubmitted: (val) {
            if (val.isNotEmpty) _submitRename(input);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (input.isNotEmpty) _submitRename(input);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submitRename(String newName) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod('rename_category', {'newName': newName});
  }

  void _promptDeleteCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
          'Are you sure you want to delete this category and all of its tasks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final uniqueChannel = WindowMethodChannel(
                'kanban_sync_${widget.windowId}',
              );
              uniqueChannel.invokeMethod('delete_category');
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = themeMode == .system
        ? MediaQuery.platformBrightnessOf(context)
        : (themeMode == .dark ? .dark : .light);

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: localSeedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return AnimatedTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StickyNoteWidget(
          title: title,
          items: items,
          windowId: widget.windowId,
          isFirst: isFirst,
          isLast: isLast,
          currentColor: localSeedColor,
          onEditCategory: _promptEditCategory,
          onDeleteCategory: _promptDeleteCategory,
          onColorChanged: (color) => setState(() => localSeedColor = color),
        ),
      ),
    );
  }
}

class StickyNoteWidget extends StatelessWidget {
  const StickyNoteWidget({
    super.key,
    required this.title,
    required this.items,
    required this.windowId,
    required this.isFirst,
    required this.isLast,
    required this.currentColor,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onColorChanged,
  });

  final String title;
  final List<String> items;
  final String windowId;
  final bool isFirst;
  final bool isLast;
  final Color currentColor;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.85),
        borderRadius: .circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _DraggableStickyNoteTitleBar(
            title: title,
            currentColor: currentColor,
            onEditCategory: onEditCategory,
            onDeleteCategory: onDeleteCategory,
            onColorChanged: onColorChanged,
          ),
          _StickyNoteWidgetContent(
            title: title,
            items: items,
            windowId: windowId,
            isFirst: isFirst,
            isLast: isLast,
          ),
        ],
      ),
    );
  }
}

class _StickyNoteWidgetContent extends StatefulWidget {
  const _StickyNoteWidgetContent({
    required this.title,
    required this.items,
    required this.windowId,
    required this.isFirst,
    required this.isLast,
  });

  final String title;
  final List<String> items;
  final String windowId;
  final bool isFirst;
  final bool isLast;

  @override
  State<_StickyNoteWidgetContent> createState() =>
      _StickyNoteWidgetContentState();
}

class _StickyNoteWidgetContentState extends State<_StickyNoteWidgetContent> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: ListView.builder(
        padding: const .all(12),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final task = widget.items[index];
          final paddedText = Padding(
            padding: const .symmetric(vertical: 12.0, horizontal: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                task,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          );

          return Dismissible(
            key: ValueKey(task),
            direction: .horizontal,
            background: _SwipeBackground(
              color: widget.isLast ? Colors.redAccent : Colors.green,
              icon: widget.isLast ? Icons.delete : Icons.arrow_forward,
              alignment: .centerLeft,
              padding: const .only(left: 16),
            ),
            secondaryBackground: _SwipeBackground(
              color: widget.isFirst ? Colors.redAccent : Colors.blue,
              icon: widget.isFirst ? Icons.delete : Icons.arrow_back,
              alignment: .centerRight,
              padding: const .only(right: 16),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                if (widget.isLast) return await _promptDelete(context, task);
                _invokeTaskAction(task, 'move_next');
                return true;
              } else {
                if (widget.isFirst) return await _promptDelete(context, task);
                _invokeTaskAction(task, 'move_prev');
                return true;
              }
            },
            onDismissed: (direction) {
              setState(() => widget.items.removeAt(index));
            },
            child: paddedText,
          );
        },
      ),
    );
  }

  void _invokeTaskAction(String task, String action) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.invokeMethod(action, {
      'category': widget.title,
      'task': task,
    });
  }

  Future<bool?> _promptDelete(BuildContext context, String task) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'This task is at the end of the board. Do you want to delete it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _invokeTaskAction(task, 'delete_task');
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    color: color,
    child: Icon(icon, color: Colors.white, size: 20),
  );
}

class _DraggableStickyNoteTitleBar extends StatelessWidget {
  const _DraggableStickyNoteTitleBar({
    required this.title,
    required this.currentColor,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onColorChanged,
  });

  final String title;
  final Color currentColor;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final titleText = Expanded(
      child: Text(
        title,
        style: TextStyle(
          fontWeight: .bold,
          fontSize: 16,
          color: colorScheme.onPrimaryContainer,
        ),
        overflow: .ellipsis,
      ),
    );

    final colorSelector = SeedColorSelector(
      currentColor: currentColor,
      color: colorScheme.onPrimaryContainer,
      onColorChanged: onColorChanged,
    );

    final contextMenuButton = PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: colorScheme.onPrimaryContainer,
      ),
      tooltip: "Category Options",
      onSelected: (value) {
        if (value == 'edit') onEditCategory();
        if (value == 'delete') onDeleteCategory();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Rename Category')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete Category', style: TextStyle(color: Colors.red)),
        ),
      ],
      constraints: const BoxConstraints(),
    );

    final closeButton = IconButton(
      icon: Icon(Icons.close, size: 18, color: colorScheme.onPrimaryContainer),
      onPressed: () async => await windowManager.close(),
      constraints: const BoxConstraints(),
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
            titleText,
            Row(
              mainAxisSize: .min,
              children: [
                colorSelector,
                contextMenuButton,
                closeButton,
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
