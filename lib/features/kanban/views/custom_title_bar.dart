import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  final VoidCallback onAddCategory;

  const CustomTitleBar({super.key, required this.onAddCategory});

  @override
  Widget build(BuildContext context) {
    final addCategoryButton = IconButton(
      onPressed: onAddCategory,
      icon: const Icon(Icons.add_box, size: 18, color: Colors.black54),
      tooltip: "Add Category",
      padding: .zero,
      constraints: const BoxConstraints(),
    );

    final verticalDivider = Container(
      width: 1,
      height: 16,
      color: Colors.black.withValues(alpha: 0.2),
    );

    final minimizeButton = IconButton(
      onPressed: () async => await windowManager.minimize(),
      icon: const Icon(Icons.minimize, size: 18, color: Colors.black54),
      padding: .zero,
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
      icon: const Icon(Icons.crop_square, size: 18, color: Colors.black54),
      padding: .zero,
      constraints: const BoxConstraints(),
    );

    final closeButton = IconButton(
      onPressed: () async => await windowManager.close(),
      icon: const Icon(Icons.close, size: 18, color: Colors.black54),
      padding: .zero,
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
            const Text(
              'Seban Board',
              style: TextStyle(fontWeight: .bold, color: Colors.black87),
            ),
            Row(
              mainAxisSize: .min,
              children: [
                addCategoryButton,
                const SizedBox(width: 12),
                verticalDivider,
                const SizedBox(width: 12),
                minimizeButton,
                const SizedBox(width: 12),
                maximizeButton,
                const SizedBox(width: 12),
                closeButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
