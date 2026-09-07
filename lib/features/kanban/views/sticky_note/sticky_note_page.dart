import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'widgets/title_bar.dart';
import 'widgets/resize_handle.dart';
import 'widgets/sticky_note_content.dart';
import '../../models/sticky_note_payload.dart';
import '../../models/ipc_event.dart';

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
  late List<Map<String, dynamic>> items;
  late bool isFirst;
  late bool isLast;
  late ThemeMode themeMode;
  late Color localSeedColor;

  @override
  void initState() {
    super.initState();

    // Parse the initial boot payload
    _updateStateFromPayload(widget.data);

    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    uniqueChannel.setMethodCallHandler((call) async {
      final event = IpcEvent.fromCall(call.method, call.arguments as Map?);
      switch (event) {
        case CloseWindowEvent():
          Future.delayed(const Duration(milliseconds: 50), () async {
            await windowManager.close();
          });
          return 'success';
        case UpdateCategoryEvent():
          setState(() => _updateStateFromPayload(event.payload));
        case _:
          break;
      }
      return 'success';
    });
  }

  void _updateStateFromPayload(Map<dynamic, dynamic> rawMap) {
    final payload = StickyNotePayload.fromMap(rawMap);

    groupId = payload.id;
    title = payload.title;
    items = payload.items;
    isFirst = payload.isFirst;
    isLast = payload.isLast;

    _applyThemeFromPayload(payload.themeMode, payload.seedColor);
  }

  void _applyThemeFromPayload(String modeStr, int incomingColorInt) {
    themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => ThemeMode.system,
    );

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

  void _submitRename(String newName) {
    if (newName.trim().isEmpty) return;
    final uniqueChannel = WindowMethodChannel('kanban_sync_${widget.windowId}');
    final event = RenameCategoryEvent(newName);
    uniqueChannel.invokeMethod(event.name, event.arguments);
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

    final stackedContent = [
      _StickyNoteWidget(
        title: title,
        items: items,
        windowId: widget.windowId,
        isFirst: isFirst,
        isLast: isLast,
        currentColor: localSeedColor,
        onEditCategory: _submitRename,
        onColorChanged: (color) => setState(() => localSeedColor = color),
        colorScheme: theme.colorScheme,
      ),
      Positioned(
        right: 0,
        bottom: 0,
        child: ResizeHandle(iconColor: theme.colorScheme.onSurfaceVariant),
      ),
    ];

    return AnimatedTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: stackedContent),
      ),
    );
  }
}

class _StickyNoteWidget extends StatelessWidget {
  const _StickyNoteWidget({
    required this.title,
    required this.items,
    required this.windowId,
    required this.isFirst,
    required this.isLast,
    required this.currentColor,
    required this.onEditCategory,
    required this.onColorChanged,
    required this.colorScheme,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String windowId;
  final bool isFirst;
  final bool isLast;
  final Color currentColor;
  final void Function(String) onEditCategory;
  final ValueChanged<Color> onColorChanged;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
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
        DraggableStickyNoteTitleBar(
          title: title,
          currentColor: currentColor,
          onEditCategory: onEditCategory,
          onColorChanged: onColorChanged,
        ),
        StickyNoteWidgetContent(
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
