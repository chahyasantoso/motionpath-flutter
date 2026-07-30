import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class MotionPathPatchPainter extends CustomPainter {
  MotionPathPatchPainter({required this.patch, this.color = Colors.blue});

  final Map<String, Object?> patch;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (patch['opacity'] as num?)?.toDouble() ?? 1;
    final x = (patch['x'] as num?)?.toDouble() ?? (patch['translateX'] as num?)?.toDouble() ?? 0;
    final y = (patch['y'] as num?)?.toDouble() ?? (patch['translateY'] as num?)?.toDouble() ?? 0;
    final rotation = (patch['rotation'] as num?)?.toDouble() ?? 0;
    final scaleX = (patch['scaleX'] as num?)?.toDouble() ?? (patch['scale'] as num?)?.toDouble() ?? 1;
    final scaleY = (patch['scaleY'] as num?)?.toDouble() ?? (patch['scale'] as num?)?.toDouble() ?? 1;

    final paint = Paint()..color = color.withOpacity(opacity.clamp(0, 1).toDouble());
    canvas.save();
    canvas.translate(size.width / 2 + x, size.height / 2 + y);
    canvas.rotate(rotation);
    canvas.scale(scaleX, scaleY);
    canvas.drawRect(const Rect.fromLTWH(-40, -40, 80, 80), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MotionPathPatchPainter oldDelegate) => oldDelegate.patch != patch || oldDelegate.color != color;
}

ui.Color colorFromPatch(Map<String, Object?> patch, {ui.Color fallback = Colors.blue}) {
  final value = patch['color'];
  if (value is ui.Color) return value;
  return fallback;
}
