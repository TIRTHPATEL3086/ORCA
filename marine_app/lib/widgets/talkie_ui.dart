import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Subtle grid-paper background used throughout the Talkie-style UI.
class GridBackground extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color lineColor;
  final double cell;

  const GridBackground({
    super.key,
    required this.child,
    this.color = AppTheme.canvas,
    this.lineColor = const Color(0x14597A5E),
    this.cell = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: CustomPaint(
        painter: _GridPainter(lineColor, cell),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;
  final double cell;

  _GridPainter(this.lineColor, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.lineColor != lineColor || old.cell != cell;
}

/// Tilted sticker label, like the "TALKIE" tags in the reference design.
class StickerLabel extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double angle;

  const StickerLabel(
    this.text, {
    super.key,
    this.color = AppTheme.indigo,
    this.textColor = Colors.white,
    this.angle = -8,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// Round pastel "badge bubble" (e.g. "24 languages", "Quiz").
class BubbleBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const BubbleBadge(
    this.text, {
    super.key,
    this.color = AppTheme.lavender,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.ink,
          fontSize: size * 0.15,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Rounded icon tile with a pastel background.
class SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  const SoftIcon(
    this.icon, {
    super.key,
    this.color = AppTheme.coralDeep,
    this.background,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Thin rounded progress bar, as in the Talkie lesson header.
class PillProgress extends StatelessWidget {
  final double value;

  const PillProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 7,
        color: AppTheme.coral,
        backgroundColor: Colors.white,
      ),
    );
  }
}
