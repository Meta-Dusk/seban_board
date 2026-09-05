import 'package:flutter/material.dart';
import 'package:seban_board/components/seed_color_selector.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  final VoidCallback onAddCategory;
  final ThemeMode currentMode;
  final Color currentColor;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<Color> onColorChanged;

  const CustomTitleBar({
    super.key,
    required this.onAddCategory,
    required this.currentMode,
    required this.currentColor,
    required this.onModeChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final addCategoryButton = IconButton(
      onPressed: onAddCategory,
      icon: Icon(
        Icons.add_box,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Add Category",
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );

    final divider = Padding(
      padding: const .symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 16,
        color: theme.colorScheme.outlineVariant,
      ),
    );

    final minimizeButton = IconButton(
      onPressed: () async => await windowManager.minimize(),
      icon: Icon(
        Icons.minimize,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );

    final maximizeButton = IconButton(
      onPressed: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      icon: Icon(
        Icons.crop_square,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );

    final closeButton = IconButton(
      onPressed: () async => await windowManager.close(),
      icon: Icon(
        Icons.close,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );

    final titleText = Text(
      'Seban Board',
      style: TextStyle(fontWeight: .bold, color: theme.colorScheme.onSurface),
    );

    return DragToMoveArea(
      child: Container(
        height: 40,
        width: double.infinity,
        color: Colors.grey.withValues(alpha: 0.1),
        alignment: Alignment.centerLeft,
        padding: const .symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            titleText,
            Row(
              // mainAxisSize: .min,
              children: [
                ThemeModeSelector(
                  currentMode: currentMode,
                  theme: theme,
                  onModeChanged: onModeChanged,
                ),
                SeedColorSelector(
                  currentColor: currentColor,
                  color: theme.colorScheme.onSurfaceVariant,
                  onColorChanged: onColorChanged,
                ),
                divider,
                addCategoryButton,
                divider,
                minimizeButton,
                maximizeButton,
                closeButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.currentMode,
    required this.theme,
    required this.onModeChanged,
  });

  final ThemeMode currentMode;
  final ThemeData theme;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<ThemeMode>(
    value: currentMode,
    underline: const SizedBox(),
    padding: const .symmetric(horizontal: 4),
    icon: Padding(
      padding: const .only(left: 4),
      child: Icon(
        Icons.brightness_medium,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    onChanged: (val) => onModeChanged(val!),
    items: [
      DropdownMenuItem(
        value: .system,
        child: Text(
          'System',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        ),
      ),
      DropdownMenuItem(
        value: .light,
        child: Text(
          'Light',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        ),
      ),
      DropdownMenuItem(
        value: .dark,
        child: Text(
          'Dark',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        ),
      ),
    ],
  );
}
