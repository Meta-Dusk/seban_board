import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

import 'core/window_manager_setup.dart';
import 'features/kanban/views/board/kanban_board_page.dart';
import 'features/kanban/views/sticky_note/sticky_note_page.dart';
import 'features/kanban/services/theme_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.init();

  // Check the current engine's controller to see if it's a sub-window
  final windowController = await WindowController.fromCurrentEngine();

  // If the window has arguments, it was spawned as a Sticky Note
  if (windowController.arguments.isNotEmpty) {
    final argument = jsonDecode(windowController.arguments);

    // Configure the sub-window
    await windowManager.ensureInitialized();
    WindowOptions stickyNoteOptions = const WindowOptions(
      size: Size(300, 350),
      minimumSize: Size(100, 150),
      backgroundColor: Colors.transparent,
      titleBarStyle: .hidden,
    );

    windowManager.waitUntilReadyToShow(stickyNoteOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.show();
    });

    runApp(
      StickyNoteApp(
        windowId: windowController.windowId,
        categoryData: argument,
      ),
    );
    return;
  }

  // If no arguments, this is the Main App starting.
  await setupMainWindow();
  runApp(const MainKanbanApp());
}

class MainKanbanApp extends StatelessWidget {
  const MainKanbanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Senban Board',
    home: const KanbanBoardPage(),
  );
}

class StickyNoteApp extends StatelessWidget {
  final String windowId;
  final Map<String, dynamic> categoryData;

  const StickyNoteApp({
    super.key,
    required this.windowId,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    // The Scaffold background will be set to transparent inside the page
    home: StickyNotePage(windowId: windowId, data: categoryData),
  );
}
