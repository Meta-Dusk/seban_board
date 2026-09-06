import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/kanban_task.dart';
import 'custom_title_bar.dart';
import 'auto_resizing_board/auto_resizing_board.dart';

class KanbanBoardPage extends StatefulWidget {
  const KanbanBoardPage({super.key});

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  final syncChannel = const WindowMethodChannel('kanban_sync');
  final Map<String, String> _activeCategoryWindows = {};

  bool _isWindowProcessing = false;
  String? _processingGroupId;

  double _columnWidth = 320.0;
  final double _minColumnWidth = 280.0;

  ThemeMode _themeMode = .system;
  Color _seedColor = Colors.blue;

  List<KanbanCategory> categories = [];

  final _tutorialCategories = [
    KanbanCategory(
      id: 'welcome',
      name: 'Welcome',
      items: [
        KanbanTask(
          'Hi, welcome to SebanBoard! This is just a simple Kanban Board app '
          'made initially for a friend of mine.',
        ),
      ],
    ),
    KanbanCategory(
      id: 'tutorial',
      name: 'Tutorial',
      items: [
        KanbanTask(
          "Click the \"Add Task\" button below to add a task... "
          "It's self-explanatory :)",
        ),
        KanbanTask(
          "You can drag tasks around, and if you swipe on them,"
          "you can either edit or delete them.",
        ),
        KanbanTask('You can simply edit all text by double-clicking them.'),
        KanbanTask(
          "Try adding a new category, by clicking the "
          "'+' button at the top-right!",
        ),
        KanbanTask("You can also drag around the categories!"),
        KanbanTask(
          "And you can even resize the categories' width by clicking and "
          "dragging the vertical bar ('|') in the header of the category.",
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    syncChannel.setMethodCallHandler((call) async {
      final payload = call.arguments as Map?;
      if (payload == null) return 'error';

      if (call.method == 'move_next') {
        _advanceTaskDirectionally(payload['category'], payload['task'], 1);
      } else if (call.method == 'move_prev') {
        _advanceTaskDirectionally(payload['category'], payload['task'], -1);
      } else if (call.method == 'delete_task') {
        _deleteTask(payload['category'], payload['task']);
      }
      return 'success';
    });

    _loadData();
  }

  // --- LOCAL STORAGE ENGINE ---

  Future<File> _getSaveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    // Creates a dedicated folder in the user's Documents
    final path = Directory('${directory.path}\\SebanBoard');
    if (!await path.exists()) {
      await path.create();
    }
    return File('${path.path}\\kanban_data.json');
  }

  Future<void> _loadData() async {
    try {
      final file = await _getSaveFile();
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        setState(() {
          categories = jsonList.map((c) => KanbanCategory.fromJson(c)).toList();
        });
      } else {
        setState(() => categories = _tutorialCategories);
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> _saveData() async {
    try {
      final file = await _getSaveFile();
      final String jsonString = jsonEncode(
        categories.map((c) => c.toJson()).toList(),
      );
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  // --- BACKUP ENGINE ---

  Future<void> _exportBackup() async {
    // Serialize the board state to a JSON string
    final String jsonString = jsonEncode(
      categories.map((c) => c.toJson()).toList(),
    );

    // Convert the string to raw bytes
    final List<int> byteList = utf8.encode(jsonString);

    final Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Export Board Backup',
      fileName: 'seban_board_backup.json',
      bytes: Uint8List.fromList(byteList),
    );

    if (outputFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup exported successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      dialogTitle: 'Import Board Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Check if the user selected a file (empty list means they canceled)
    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      setState(() {
        categories = jsonList.map((c) => KanbanCategory.fromJson(c)).toList();
      });

      await _saveData();
      _broadcastAllUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Clamps the width so it can never crush the UI or expand infinitely
  void _handleColumnResize(double delta) => setState(() {
    _columnWidth = (_columnWidth + delta).clamp(_minColumnWidth, 800.0);
  });

  // --- Theme Updaters ---
  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _broadcastAllUpdates(); // Sync to sticky notes
  }

  void _updateSeedColor(Color color) {
    setState(() => _seedColor = color);
    _broadcastAllUpdates(); // Sync to sticky notes
  }

  void _broadcastAllUpdates() {
    for (KanbanCategory group in categories) {
      _broadcastUpdate(group.id);
    }
  }

  ThemeData _getCurrentTheme() {
    final Brightness brightness = _themeMode == .system
        ? MediaQuery.platformBrightnessOf(context)
        : (_themeMode == .dark ? .dark : .light);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  // --- Kanban Logic Methods ---
  void _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) {
    setState(() {
      final movedTask = categories[oldListIndex].items.removeAt(oldItemIndex);
      categories[newListIndex].items.insert(newItemIndex, movedTask);
    });

    _broadcastUpdate(categories[oldListIndex].id);
    if (oldListIndex != newListIndex) {
      _broadcastUpdate(categories[newListIndex].id);
    }
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      final movedList = categories.removeAt(oldListIndex);
      categories.insert(newListIndex, movedList);
    });
  }

  // --- CATEGORY CRUD METHODS ---

  void _submitAddCategory(String categoryName) {
    final newGroupId = categoryName.toLowerCase().replaceAll(' ', '_');
    setState(() {
      categories.add(
        KanbanCategory(id: newGroupId, name: categoryName, items: []),
      );
    });
  }

  void _submitEditCategory(String groupId, String newName) {
    if (newName.trim().isEmpty) return;
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      setState(() {
        final oldGroup = categories[groupIndex];
        categories[groupIndex] = KanbanCategory(
          id: oldGroup.id,
          name: newName,
          items: oldGroup.items,
        );
      });
      _broadcastUpdate(groupId);
    }
  }

  void _promptDeleteCategory(String groupId) {
    final theme = _getCurrentTheme();
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
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
                setState(() => categories.removeWhere((g) => g.id == groupId));
                if (_activeCategoryWindows.containsKey(groupId)) {
                  final windowIdStr = _activeCategoryWindows[groupId]!;
                  final uniqueChannel = WindowMethodChannel(
                    'kanban_sync_$windowIdStr',
                  );
                  uniqueChannel.invokeMethod('close_window');
                  _activeCategoryWindows.remove(groupId);
                }
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  // --- TASK CRUD METHODS ---

  void _submitAddTask(String groupId, String taskTitle) {
    final group = categories.firstWhere((g) => g.id == groupId);
    setState(() {
      group.items.add(KanbanTask(taskTitle));
    });
    _broadcastUpdate(groupId);
  }

  void _submitEditTask(String groupId, KanbanTask oldTask, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    final group = categories.firstWhere((g) => g.id == groupId);
    final index = group.items.indexWhere((t) => t.id == oldTask.id);
    if (index != -1) {
      setState(() {
        group.items[index] = KanbanTask(newTitle);
      });
      _broadcastUpdate(groupId);
    }
  }

  void _promptDeleteTask(String groupId, KanbanTask task) {
    final theme = _getCurrentTheme();
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          title: const Text('Delete Task?'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final group = categories.firstWhere((g) => g.id == groupId);
                setState(() {
                  group.items.removeWhere((t) => t.id == task.id);
                });
                _broadcastUpdate(groupId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _advanceTaskDirectionally(
    String categoryName,
    String taskTitle,
    int direction,
  ) {
    final groupIndex = categories.indexWhere((g) => g.name == categoryName);
    if (groupIndex == -1) return;

    final targetIndex = groupIndex + direction;
    if (targetIndex < 0 || targetIndex >= categories.length) return;

    final currentGroup = categories[groupIndex];
    final targetGroup = categories[targetIndex];

    final taskIndex = currentGroup.items.indexWhere(
      (t) => t.title == taskTitle,
    );
    if (taskIndex != -1) {
      setState(() {
        final taskItem = currentGroup.items.removeAt(taskIndex);
        targetGroup.items.add(taskItem);
      });
      _broadcastUpdate(currentGroup.id);
      _broadcastUpdate(targetGroup.id);
    }
  }

  void _deleteTask(String categoryName, String taskTitle) {
    final group = categories.firstWhere((g) => g.name == categoryName);
    setState(() {
      group.items.removeWhere((t) => t.title == taskTitle);
    });
    _broadcastUpdate(group.id);
  }

  void _renameCategoryFromSticky(String groupId, String newName) {
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      setState(() {
        categories[groupIndex] = KanbanCategory(
          id: groupId,
          name: newName,
          items: categories[groupIndex].items,
        );
      });
      _broadcastUpdate(groupId);
    }
  }

  void _deleteCategoryFromSticky(String groupId) {
    setState(() => categories.removeWhere((g) => g.id == groupId));
    if (_activeCategoryWindows.containsKey(groupId)) {
      final windowIdStr = _activeCategoryWindows[groupId]!;
      final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');
      uniqueChannel.invokeMethod('close_window');
      _activeCategoryWindows.remove(groupId);
    }
  }

  Future<void> _handlePopOutCategory(KanbanCategory columnData) async {
    if (_isWindowProcessing) return;

    final groupId = columnData.id;
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    final group = categories[groupIndex];

    setState(() {
      _isWindowProcessing = true;
      _processingGroupId = groupId;
    });

    try {
      if (_activeCategoryWindows.containsKey(groupId)) {
        final windowIdStr = _activeCategoryWindows[groupId]!;
        final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');

        bool closeSuccess = false;
        try {
          await uniqueChannel.invokeMethod('close_window');
          closeSuccess = true;
        } catch (_) {
          debugPrint('Window was already dead.');
        }

        _activeCategoryWindows.remove(groupId);
        if (closeSuccess) return;
      }

      final payload = jsonEncode({
        'id': group.id,
        'title': group.name,
        'items': group.items.map((item) => item.title).toList(),
        'isFirst': groupIndex == 0,
        'isLast': groupIndex == categories.length - 1,
        'themeMode': _themeMode.name,
        'seedColor': _seedColor.toARGB32(),
      });

      final window = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: payload),
      );

      final windowId = window.windowId;
      _activeCategoryWindows[groupId] = windowId.toString();

      final uniqueChannel = WindowMethodChannel('kanban_sync_$windowId');
      uniqueChannel.setMethodCallHandler((call) async {
        final payload = call.arguments as Map?;
        if (payload == null) return 'error';

        if (call.method == 'rename_category') {
          _renameCategoryFromSticky(groupId, payload['newName']);
        } else if (call.method == 'delete_category') {
          _deleteCategoryFromSticky(groupId);
        } else if (call.method == 'move_next') {
          _advanceTaskDirectionally(payload['category'], payload['task'], 1);
        } else if (call.method == 'move_prev') {
          _advanceTaskDirectionally(payload['category'], payload['task'], -1);
        } else if (call.method == 'delete_task') {
          _deleteTask(payload['category'], payload['task']);
        } else if (call.method == 'edit_task') {
          _submitEditTask(
            groupId,
            KanbanTask(payload['oldTask']),
            payload['newTask'],
          );
        }
        return 'success';
      });
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _isWindowProcessing = false;
          _processingGroupId = null;
        });
      }
    }
  }

  void _broadcastUpdate(String groupId) async {
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;
    final group = categories[groupIndex];

    final payload = {
      'id': group.id,
      'title': group.name,
      'items': group.items.map((item) => item.title).toList(),
      'isFirst': groupIndex == 0,
      'isLast': groupIndex == categories.length - 1,
      'themeMode': _themeMode.name,
      'seedColor': _seedColor.toARGB32(),
    };

    // ONLY send the update to this specific category's window
    if (_activeCategoryWindows.containsKey(groupId)) {
      final windowIdStr = _activeCategoryWindows[groupId]!;
      try {
        final uniqueChannel = WindowMethodChannel('kanban_sync_$windowIdStr');
        await uniqueChannel.invokeMethod('update_category', payload);
      } catch (e) {
        debugPrint('Sticky note $windowIdStr not listening: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = _themeMode == .system
        ? MediaQuery.platformBrightnessOf(context)
        : (_themeMode == .dark ? .dark : .light);

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return AnimatedTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          mainAxisAlignment: .center,
          children: [
            CustomTitleBar(
              onAddCategory: _submitAddCategory,
              onExportBackup: _exportBackup,
              onImportBackup: _importBackup,
              currentMode: _themeMode,
              currentColor: _seedColor,
              onModeChanged: _updateThemeMode,
              onColorChanged: _updateSeedColor,
            ),
            AutoResizingBoard(
              categories: categories,
              columnWidth: _columnWidth,
              onColumnResize: _handleColumnResize,
              onItemReorder: _onItemReorder,
              onListReorder: _onListReorder,
              onPopOutCategory: _handlePopOutCategory,
              onAddTask: _submitAddTask,
              onEditTask: _submitEditTask,
              onDeleteTask: _promptDeleteTask,
              onEditCategory: _submitEditCategory,
              onDeleteCategory: _promptDeleteCategory,
              isProcessing: _isWindowProcessing,
              processingGroupId: _processingGroupId,
            ),
          ],
        ),
      ),
    );
  }
}
