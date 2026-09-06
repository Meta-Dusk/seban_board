import 'package:flutter/material.dart';
import 'package:seban_board/components/seed_color_selector.dart';
import 'package:seban_board/components/theme_mode_selector.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  final void Function(String categoryName) onAddCategory;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final ThemeMode currentMode;
  final Color currentColor;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<Color> onColorChanged;

  const CustomTitleBar({
    super.key,
    required this.onAddCategory,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.currentMode,
    required this.currentColor,
    required this.onModeChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    final importButton = IconButton(
      onPressed: onImportBackup,
      icon: Icon(
        Icons.file_download_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Import Backup",
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );

    final exportButton = IconButton(
      onPressed: onExportBackup,
      icon: Icon(
        Icons.file_upload_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Export Backup",
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
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
              children: [
                ThemeModeSelector(
                  currentMode: currentMode,
                  theme: theme,
                  onModeChanged: onModeChanged,
                ),
                SeedColorSelector(
                  currentColor: currentColor,
                  onColorChanged: onColorChanged,
                ),
                importButton,
                exportButton,

                divider,
                _InlineAddCategoryButton(
                  onAddCategory: onAddCategory,
                  theme: theme,
                ),

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

class _InlineAddCategoryButton extends StatefulWidget {
  final void Function(String) onAddCategory;
  final ThemeData theme;

  const _InlineAddCategoryButton({
    required this.onAddCategory,
    required this.theme,
  });

  @override
  State<_InlineAddCategoryButton> createState() =>
      _InlineAddCategoryButtonState();
}

class _InlineAddCategoryButtonState extends State<_InlineAddCategoryButton> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _saveAndClose();
    });
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
    if (text.isNotEmpty) {
      widget.onAddCategory(text);
    }
    _controller.clear();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 140,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(
            color: widget.theme.colorScheme.onSurface,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'New Category...',
            hintStyle: TextStyle(
              color: widget.theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              ),
            ),
            isDense: true,
            contentPadding: const .symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: .circular(4),
              borderSide: .none,
            ),
            filled: true,
            fillColor: widget.theme.colorScheme.surfaceContainerHighest,
          ),
          onSubmitted: (_) => _saveAndClose(),
        ),
      );
    }

    return IconButton(
      onPressed: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      icon: Icon(
        Icons.add_box,
        size: 18,
        color: widget.theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: "Add Category",
      padding: const .symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );
  }
}
