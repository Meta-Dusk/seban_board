import 'package:flutter/material.dart';

class SeedColorSelector extends StatelessWidget {
  const SeedColorSelector({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  static const colorList = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.circle, color: currentColor, size: 16),
    tooltip: "Cycle Theme Color",
    padding: const .symmetric(horizontal: 8),
    constraints: const BoxConstraints(),
    onPressed: () {
      // Find the current color's index (using toARGB32() for strict safety)
      int currentIndex = colorList.indexWhere(
        (c) => c.toARGB32() == currentColor.toARGB32(),
      );

      // If not found (fallback), default to 0. Otherwise, increment and wrap around.
      if (currentIndex == -1) currentIndex = 0;
      final nextIndex = (currentIndex + 1) % colorList.length;

      onColorChanged(colorList[nextIndex]);
    },
  );
}
