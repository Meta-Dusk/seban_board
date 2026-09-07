import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class ResizeHandle extends StatelessWidget {
  final Color iconColor;

  const ResizeHandle({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeUpLeftDownRight,
    child: GestureDetector(
      // Trigger the native OS window resize behavior
      onPanStart: (details) {
        windowManager.startResizing(.bottomRight);
      },
      child: Container(
        color: Colors.transparent,
        padding: const .all(4.0),
        child: Icon(
          Icons.zoom_out_map,
          size: 16,
          color: iconColor.withValues(alpha: 0.5),
        ),
      ),
    ),
  );
}
