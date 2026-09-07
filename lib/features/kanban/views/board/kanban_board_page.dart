import 'package:flutter/material.dart';
import 'package:seban_board/features/kanban/services/theme_service.dart';

import 'package:window_manager/window_manager.dart';

import 'package:seban_board/core/constants/assets.dart';
import '../../mixins/category_trigger_mixin.dart';
import '../../models/kanban.dart';
import '../../services/birthday_service.dart';
import '../../services/window_sync_service.dart';
import '../../services/storage_service.dart';
import 'auto_resizing_board/auto_resizing_board.dart';
import 'custom_title_bar.dart';

class KanbanBoardPage extends StatefulWidget {
  const KanbanBoardPage({super.key});

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage>
    with WindowListener, CategoryTriggerMixin {
  final _storage = StorageService();
  final _birthdayService = BirthdayService();
  final _windowSync = WindowSyncService();

  bool _isWindowProcessing = false;
  String? _processingGroupId;
  String? _exitingGroupId;

  double _columnWidth = 320.0;
  final double _minColumnWidth = 280.0;

  List<KanbanCategory> categories = [];

  bool get _isBirthday => _birthdayService.isBirthday;

  void _triggerBirthday() {
    // Pass the categories list directly to the service
    final wasActivated = _birthdayService.applyBirthdayEvent(categories);

    if (wasActivated) {
      setState(() {});
      _saveData();
      _broadcastAllUpdates();
    }
  }

  @override
  void initState() {
    super.initState();

    windowManager.addListener(this);
    _initCloseInterceptor();

    _windowSync.initMainListener(
      onMoveTask: _advanceTaskDirectionally,
      onDeleteTask: _deleteTask,
    );

    _loadData();

    ThemeService.themeMode.addListener(_broadcastAllUpdates);
    ThemeService.seedColor.addListener(_broadcastAllUpdates);
  }

  Future<void> _initCloseInterceptor() async {
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    await _saveData();
    await windowManager.destroy();
  }

  @override
  void dispose() {
    ThemeService.themeMode.removeListener(_broadcastAllUpdates);
    ThemeService.seedColor.removeListener(_broadcastAllUpdates);
    windowManager.removeListener(this);
    super.dispose();
  }

  // --- LOCAL STORAGE ENGINE ---
  Future<void> _loadData() async {
    final loadedCategories = await _storage.loadData();
    setState(() {
      categories = loadedCategories ?? Assets.categories.tutorials;
    });
  }

  Future<void> _saveData() async => await _storage.saveData(categories);

  Future<void> _exportBackup() async {
    final success = await _storage.exportBackup(categories);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup exported successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    final importedCategories = await _storage.importBackup();
    if (importedCategories != null) {
      setState(() => categories = importedCategories);
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

  void _broadcastAllUpdates() {
    for (KanbanCategory group in categories) {
      _broadcastUpdate(group.id);
    }
  }

  ThemeData _getCurrentTheme() {
    final Brightness brightness = ThemeService.themeMode.value == .system
        ? MediaQuery.platformBrightnessOf(context)
        : (ThemeService.themeMode.value == .dark ? .dark : .light);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeService.seedColor.value,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  // --- KANBAN LOGIC METHODS ---
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
    final startingItems = getPresetTasksForCategory(categoryName);

    setState(() {
      categories.add(
        KanbanCategory(
          id: newGroupId,
          name: categoryName,
          items: startingItems,
        ),
      );
    });

    _saveData();
    _broadcastAllUpdates();
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
      builder: (context) {
        final deleteButton = TextButton(
          onPressed: () async {
            Navigator.pop(context);
            setState(() => _exitingGroupId = groupId);
            await Future.delayed(const Duration(milliseconds: 300));

            if (!mounted) return;

            setState(() {
              categories.removeWhere((g) => g.id == groupId);
              _exitingGroupId = null;
            });

            _windowSync.closeWindow(groupId);
            _saveData();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        );

        final cancelButton = TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        );

        return Theme(
          data: theme,
          child: AlertDialog(
            title: const Text('Delete Category?'),
            content: const Text(
              'Are you sure you want to delete this category and all of its tasks?',
            ),
            actions: [cancelButton, deleteButton],
          ),
        );
      },
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
        group.items[index] = KanbanTask(
          newTitle,
          imagePath: group.items[index].imagePath,
        );
      });
      _saveData();
      _broadcastUpdate(groupId);
    }
  }

  Future<bool> _promptDeleteTask(String groupId, KanbanTask task) async {
    final theme = _getCurrentTheme();
    final colorScheme = theme.colorScheme;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          title: Text(
            'Delete Task?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          backgroundColor: colorScheme.surfaceContainerHigh,
          actions: [
            // Return FALSE to cancel the swipe
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            // Return TRUE to trigger the shrink animation
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    return confirm ?? false;
  }

  void _executeTaskDismissal(String groupId, KanbanTask task) {
    final group = categories.firstWhere((g) => g.id == groupId);
    setState(() {
      group.items.removeWhere((t) => t.id == task.id);
    });
    _saveData();
    _broadcastUpdate(groupId);
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

  // --- STICKY NOTE METHODS ---
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
    _windowSync.closeWindow(groupId);
    _saveData();
  }

  Future<void> _handlePopOutCategory(KanbanCategory columnData) async {
    if (_isWindowProcessing) return;

    final groupId = columnData.id;
    final groupIndex = categories.indexWhere((g) => g.id == groupId);

    setState(() {
      _isWindowProcessing = true;
      _processingGroupId = groupId;
    });

    try {
      await _windowSync.toggleStickyNote(
        group: categories[groupIndex],
        groupIndex: groupIndex,
        totalGroups: categories.length,
        themeModeName: ThemeService.themeMode.value.name,
        seedColorValue: ThemeService.seedColor.value.toARGB32(),
        onRenameCategory: _renameCategoryFromSticky,
        onDeleteCategory: _deleteCategoryFromSticky,
        onMoveTask: _advanceTaskDirectionally,
        onDeleteTask: _deleteTask,
        onEditTask: _submitEditTask,
      );
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

  void _broadcastUpdate(String groupId) {
    final groupIndex = categories.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    _windowSync.broadcastUpdate(
      group: categories[groupIndex],
      groupIndex: groupIndex,
      totalGroups: categories.length,
      themeModeName: ThemeService.themeMode.value.name,
      seedColorValue: ThemeService.seedColor.value.toARGB32(),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ThemeService.themeMode,
      ThemeService.seedColor,
    ]),
    builder: (context, _) {
      final mode = ThemeService.themeMode.value;
      final seed = ThemeService.seedColor.value;

      final Brightness brightness = mode == .system
          ? MediaQuery.platformBrightnessOf(context)
          : (mode == .dark ? .dark : .light);

      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
        ),
        useMaterial3: true,
      );

      final mainContent = [
        CustomTitleBar(
          onAddCategory: _submitAddCategory,
          onExportBackup: _exportBackup,
          onImportBackup: _importBackup,
          isBirthday: _isBirthday,
          onBirthday: _triggerBirthday,
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
          onDeleteTaskPrompt: _promptDeleteTask,
          onTaskDismissed: _executeTaskDismissal,
          onEditCategory: _submitEditCategory,
          onDeleteCategory: _promptDeleteCategory,
          exitingGroupId: _exitingGroupId,
          isProcessing: _isWindowProcessing,
          processingGroupId: _processingGroupId,
        ),
      ];

      return AnimatedTheme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Column(mainAxisAlignment: .center, children: mainContent),
        ),
      );
    },
  );
}
