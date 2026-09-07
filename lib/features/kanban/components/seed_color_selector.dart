import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class SeedColorSelector extends StatelessWidget {
  const SeedColorSelector({super.key});

  static const List<Color> palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Color>(
    valueListenable: ThemeService.seedColor,
    builder: (context, currentColor, _) => IconButton(
      tooltip: 'Cycle Seed Color',
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
      icon: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: currentColor,
          shape: .circle,
          border: .all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
      ),
      onPressed: () {
        final currentIndex = palette.indexOf(currentColor);
        final nextIndex = currentIndex == -1
            ? 0
            : (currentIndex + 1) % palette.length;
        ThemeService.setSeedColor(palette[nextIndex]);
      },
    ),
  );
}
