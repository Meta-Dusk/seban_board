import 'package:flutter/material.dart';
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
  late String title;
  late List<String> items;

  @override
  void initState() {
    super.initState();
    // Initialize state with the arguments passed during creation
    title = widget.data['title'] ?? "Notes";
    items = List<String>.from(widget.data['items'] ?? []);

    // Bind to the unique channel for this specific window
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');

    uniqueChannel.setMethodCallHandler((call) async {
      // Handle the assassination order
      if (call.method == 'close_window') {
        Future.delayed(const Duration(milliseconds: 50), () async {
          await windowManager.close();
        });
        return 'success';
      }
      // Handle standard task updates
      else if (call.method == 'update_category' && call.arguments != null) {
        final payload = call.arguments as Map;
        // Check if it's meant for this category just in case
        if (payload['title'] == title) {
          setState(() {
            items = List<String>.from(payload['items']);
          });
        }
      }
      return 'success';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Padding(
      padding: const .all(12.0),
      child: StickyNoteWidget(
        title: title,
        items: items,
        windowId: widget.windowId,
      ),
    ),
  );
}

class StickyNoteWidget extends StatelessWidget {
  const StickyNoteWidget({
    super.key,
    required this.title,
    required this.items,
    required this.windowId,
  });

  final String title;
  final List<String> items;
  final String windowId;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.amberAccent.withValues(alpha: 0.85),
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
        _DraggableStickyNoteTitleBar(title: title),
        _StickyNoteWidgetContent(
          title: title,
          items: items,
          windowId: windowId,
        ),
      ],
    ),
  );
}

class _StickyNoteWidgetContent extends StatelessWidget {
  const _StickyNoteWidgetContent({
    required this.title,
    required this.items,
    required this.windowId,
  });

  final String title;
  final List<String> items;
  final String windowId;

  @override
  Widget build(BuildContext context) => Expanded(
    child: ListView.builder(
      padding: const .all(12),
      itemCount: items.length,
      itemBuilder: (context, index) => Padding(
        padding: const .symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: .center,
          crossAxisAlignment: .start,
          children: [
            IconButton(
              onPressed: () => _checkOutTask(index),
              icon: Icon(
                Icons.open_in_new,
                size: 20,
                color: Colors.black.withValues(alpha: .6),
              ),
              alignment: .topStart,
              tooltip: 'Move to next category',
            ),
            const SizedBox(width: 8),
            Text(
              items[index],
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _checkOutTask(int index) {
    final uniqueChannel = WindowMethodChannel('kanban_sync_$windowId');
    uniqueChannel.invokeMethod('check_out_task', {
      'category': title,
      'task': items[index],
    });
  }
}

class _DraggableStickyNoteTitleBar extends StatelessWidget {
  const _DraggableStickyNoteTitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => DragToMoveArea(
    child: Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: .bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
            padding: .zero,
            constraints: const BoxConstraints(),
            onPressed: () async => await windowManager.close(),
          ),
        ],
      ),
    ),
  );
}
