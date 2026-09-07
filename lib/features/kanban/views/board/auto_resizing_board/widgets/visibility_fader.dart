import 'package:flutter/material.dart';

class VisibilityFader extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const VisibilityFader({
    super.key,
    required this.child,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    builder: (_, value, child) => Opacity(
      opacity: value.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.95 + (0.05 * value),
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
    ),
    child: child,
  );
}
