import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and slides its child in the first time it scrolls into view.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 28),
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * 0.92) {
      _started = true;
      _position?.removeListener(_check);
      if (_reduceMotion(context)) {
        _c.value = 1;
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _c.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: child,
          ),
        );
      },
    );
  }
}

/// Animated number that counts up once it becomes visible.
class CountUp extends StatelessWidget {
  final int value;
  final String suffix;
  final TextStyle style;

  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return WhenVisible(
      builder: (context, visible) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: visible ? value.toDouble() : 0),
        duration: _reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
      ),
    );
  }
}

/// Rebuilds with `visible: true` once this widget scrolls into view.
class WhenVisible extends StatefulWidget {
  final Widget Function(BuildContext context, bool visible) builder;

  const WhenVisible({super.key, required this.builder});

  @override
  State<WhenVisible> createState() => _WhenVisibleState();
}

class _WhenVisibleState extends State<WhenVisible> {
  ScrollPosition? _position;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_visible || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _position?.removeListener(_check);
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _visible);
}

/// Continuously scrolling horizontal strip (e.g. data sources).
class Marquee extends StatefulWidget {
  final List<Widget> children;
  final double speed;
  final double gap;

  const Marquee({
    super.key,
    required this.children,
    this.speed = 30,
    this.gap = 10,
  });

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final _key = GlobalKey();
  double _stripWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null || !box.hasSize) return;
    _stripWidth = box.size.width + widget.gap;
    if (_reduceMotion(context) || _stripWidth <= 0) return;
    _c.duration = Duration(
      milliseconds: (_stripWidth / widget.speed * 1000).round(),
    );
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget strip({Key? key}) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in widget.children) ...[
              child,
              SizedBox(width: widget.gap),
            ],
          ],
        );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: double.infinity,
          child: Transform.translate(
            offset: Offset(-_c.value * _stripWidth, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [strip(key: _key), strip(), strip()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gentle vertical bobbing, used for floating illustrations.
class FloatY extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration period;

  const FloatY({
    super.key,
    required this.child,
    this.distance = 8,
    this.period = const Duration(milliseconds: 2600),
  });

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          -widget.distance * Curves.easeInOut.transform(_c.value),
        ),
        child: child,
      ),
    );
  }
}

/// Three pulsing dots, as in a "typing…" indicator.
class TypingDots extends StatefulWidget {
  final Color color;

  const TypingDots({super.key, this.color = AppTheme.muted});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.3 +
                      0.7 *
                          (0.5 +
                              0.5 *
                                  math.sin(
                                    (_c.value * 2 * math.pi) - i * 0.9,
                                  )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft animated waves along the bottom of a hero block.
class AnimatedWaves extends StatefulWidget {
  final double height;
  final Color color;

  const AnimatedWaves({
    super.key,
    this.height = 46,
    this.color = AppTheme.coral,
  });

  @override
  State<AnimatedWaves> createState() => _AnimatedWavesState();
}

class _AnimatedWavesState extends State<AnimatedWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _WavePainter(_c.value, widget.color),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final Color color;

  _WavePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double amp, double phase, double yBase, double alpha) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final y = yBase +
            amp *
                math.sin((x / size.width * 2 * math.pi * 1.4) +
                    (t * 2 * math.pi) +
                    phase);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
    }

    wave(6, 0, size.height * 0.35, 0.25);
    wave(7, 2.1, size.height * 0.5, 0.45);
    wave(5, 4.2, size.height * 0.68, 1);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}

/// Scales down slightly while pressed — tactile feedback for cards.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressScale({super.key, required this.child, this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
