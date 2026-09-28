import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum MascotMood { happy, sparkle, sleepy, calm }

/// Friendly blob mascot in the Talkie style — a soft coral body with a
/// little dorsal fin (it's an orca, after all) and a simple face.
class OrcaMascot extends StatelessWidget {
  final double size;
  final MascotMood mood;
  final Color color;
  final bool halo;

  const OrcaMascot({
    super.key,
    this.size = 120,
    this.mood = MascotMood.happy,
    this.color = AppTheme.coral,
    this.halo = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter(mood, color, halo)),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final Color color;
  final bool halo;

  _MascotPainter(this.mood, this.color, this.halo);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w * 0.5, w * 0.56);
    final r = w * 0.40;

    if (halo) {
      canvas.drawCircle(
        c,
        r * 1.14,
        Paint()..color = AppTheme.sage.withValues(alpha: 0.9),
      );
    }

    final body = Paint()..color = color;

    // Dorsal fin + little bump, like Talkie's ears.
    final fin = Path()
      ..moveTo(c.dx + r * 0.20, c.dy - r * 0.86)
      ..quadraticBezierTo(
        c.dx + r * 0.40,
        c.dy - r * 1.42,
        c.dx + r * 0.78,
        c.dy - r * 1.30,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.62,
        c.dy - r * 1.02,
        c.dx + r * 0.66,
        c.dy - r * 0.66,
      )
      ..close();
    canvas.drawPath(fin, body);
    canvas.drawCircle(
      Offset(c.dx + r * 0.02, c.dy - r * 0.98),
      r * 0.17,
      body,
    );

    canvas.drawCircle(c, r, body);

    final ink = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = AppTheme.ink;

    final eyeL = Offset(c.dx - r * 0.34, c.dy - r * 0.12);
    final eyeR = Offset(c.dx + r * 0.20, c.dy - r * 0.08);
    final eyeW = r * 0.24;

    switch (mood) {
      case MascotMood.sparkle:
        for (final e in [eyeL, eyeR]) {
          canvas.drawCircle(e, r * 0.15, fill);
          _star(canvas, e, r * 0.09);
        }
      case MascotMood.happy:
        for (final e in [eyeL, eyeR]) {
          canvas.drawArc(
            Rect.fromCenter(center: e, width: eyeW, height: eyeW * 0.8),
            math.pi * 1.1,
            math.pi * 0.8,
            false,
            ink,
          );
        }
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx - r * 0.07, c.dy + r * 0.18),
            width: r * 0.26,
            height: r * 0.2,
          ),
          0.1,
          math.pi - 0.2,
          false,
          ink,
        );
      case MascotMood.sleepy:
        for (final e in [eyeL, eyeR]) {
          canvas.drawArc(
            Rect.fromCenter(center: e, width: eyeW, height: eyeW * 0.7),
            0.15,
            math.pi - 0.3,
            false,
            ink,
          );
        }
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx - r * 0.07, c.dy + r * 0.26),
            width: r * 0.2,
            height: r * 0.16,
          ),
          0.1,
          math.pi - 0.2,
          false,
          ink,
        );
      case MascotMood.calm:
        for (final e in [eyeL, eyeR]) {
          canvas.drawCircle(e, r * 0.075, fill);
        }
    }
  }

  void _star(Canvas canvas, Offset c, double s) {
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.mood != mood || old.color != color || old.halo != halo;
}
