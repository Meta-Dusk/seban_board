import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import 'startup_toggle.dart';

class SettingsDropdown extends StatefulWidget {
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final bool isBirthday;
  final VoidCallback onBirthday;

  const SettingsDropdown({
    super.key,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.isBirthday,
    required this.onBirthday,
  });

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconAnimController;

  static const List<Color> _palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      onOpen: () => _iconAnimController.forward(),
      onClose: () => _iconAnimController.reverse(),
      builder: (_, controller, _) => IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.25).animate(
            CurvedAnimation(
              parent: _iconAnimController,
              curve: Curves.easeInOutBack,
            ),
          ),
          child: Icon(
            Icons.settings,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        tooltip: "Settings & Options",
        padding: const .symmetric(horizontal: 8),
        constraints: const BoxConstraints(),
      ),
      menuChildren: [
        const Padding(
          padding: .symmetric(horizontal: 16, vertical: 8),
          child: StartupToggle(),
        ),
        const Divider(),
        const Padding(
          padding: .symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('Theme Mode'),
              SizedBox(height: 8),
              _ThemeModeButton(),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const .symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Text('Theme Color'),
              const SizedBox(height: 12),
              _ThemeColorButton(palette: _palette, colorScheme: colorScheme),
            ],
          ),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_download_outlined, size: 18),
          onPressed: widget.onImportBackup,
          child: const Text('Import Backup'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_upload_outlined, size: 18),
          onPressed: widget.onExportBackup,
          child: const Text('Export Backup'),
        ),
        if (widget.isBirthday) ...[
          const Divider(),
          MenuItemButton(
            leadingIcon: const Icon(
              Icons.card_giftcard,
              size: 18,
              color: Colors.purple,
            ),
            onPressed: widget.onBirthday,
            child: const Text('Special Surprise'),
          ),
        ],
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeService.themeMode,
    builder: (_, currentMode, _) => SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: .system,
          icon: Icon(Icons.brightness_auto, size: 16),
          label: Text('Auto'),
        ),
        ButtonSegment(
          value: .light,
          icon: Icon(Icons.light_mode, size: 16),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: .dark,
          icon: Icon(Icons.dark_mode, size: 16),
          label: Text('Dark'),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (newSelection) {
        ThemeService.setMode(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        visualDensity: .compact,
        textStyle: const TextStyle(fontSize: 12),
      ),
    ),
  );
}

class _ThemeColorButton extends StatelessWidget {
  const _ThemeColorButton({
    required List<Color> palette,
    required this.colorScheme,
  }) : _palette = palette;

  final List<Color> _palette;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Color>(
    valueListenable: ThemeService.seedColor,
    builder: (_, currentColor, _) => Row(
      mainAxisSize: .min,
      children: _palette.map((color) {
        final isSelected = color.toARGB32() == currentColor.toARGB32();

        final container = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: .circle,
            border: .all(
              color: isSelected ? colorScheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        );

        return Padding(
          padding: const .only(right: 12.0),
          child: InkWell(
            onTap: () => ThemeService.setSeedColor(color),
            customBorder: const CircleBorder(),
            child: container,
          ),
        );
      }).toList(),
    ),
  );
}
