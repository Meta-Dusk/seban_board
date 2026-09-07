import 'package:flutter/material.dart';

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
