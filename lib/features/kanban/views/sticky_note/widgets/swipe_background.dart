import 'package:flutter/material.dart';

class SwipeBackground extends StatelessWidget {
  const SwipeBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
    required this.padding,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: padding,
    color: color,
    child: Icon(icon, color: Colors.white, size: 20),
  );
}
