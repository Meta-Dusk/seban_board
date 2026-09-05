import 'package:flutter/material.dart';

class SeedColorSelector extends StatelessWidget {
  const SeedColorSelector({
    super.key,
    required this.currentColor,
    required this.color,
    required this.onColorChanged,
  });

  final Color currentColor;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    const colorList = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    final mappedColors = colorList.map(
      (color) => DropdownMenuItem(
        value: color,
        alignment: .center,
        child: Icon(Icons.circle, color: color, size: 16),
      ),
    );

    return DropdownButton<Color>(
      value: currentColor,
      underline: const SizedBox(),
      padding: const .symmetric(horizontal: 4),
      icon: Icon(Icons.color_lens, size: 16, color: color),
      onChanged: (val) => onColorChanged(val!),
      items: mappedColors.toList(),
    );
  }
}
