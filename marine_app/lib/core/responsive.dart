import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Screen-size helpers so every screen adapts from tiny phones (320dp)
/// up to tablets, foldables and landscape.
class Responsive {
  Responsive._();

  /// Design reference width (iPhone 14).
  static const double baseWidth = 390;

  /// Widest the phone-style layout grows before it is centred.
  static const double maxContentWidth = 560;

  static const double compactWidth = 360;
  static const double tabletWidth = 600;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compactWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tabletWidth;

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  /// Scale factor relative to the design width, clamped so layouts never
  /// get cramped on small phones or cartoonish on large ones.
  static double scale(BuildContext context) {
    final width = math.min(widthOf(context), maxContentWidth);
    return (width / baseWidth).clamp(0.82, 1.12);
  }

  /// Scale for illustrations: follows width, but shrinks on short
  /// (landscape) screens so artwork never crowds out the content.
  static double artScale(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return math.min(scale(context), (height / 700).clamp(0.55, 1.12));
  }

  /// Horizontal page padding that tightens on small phones.
  static double gutter(BuildContext context) {
    final width = widthOf(context);
    if (width < compactWidth) return 14;
    if (width < 400) return 18;
    return 22;
  }

  /// Keeps accessibility text scaling usable without breaking layouts,
  /// and centres the phone layout on tablets, desktops and the web.
  static Widget appBuilder(BuildContext context, Widget? child) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, maxContentWidth);
    // Gentle size-based type scaling on top of the user's own setting.
    final widthFactor = (width / baseWidth).clamp(0.9, 1.06);
    final textScale = media.textScaler.scale(1).clamp(0.9, 1.3) * widthFactor;

    Widget content = MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(textScale)),
      child: child ?? const SizedBox.shrink(),
    );

    if (media.size.width > maxContentWidth) {
      content = ColoredBox(
        color: AppTheme.mint,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
                size: Size(maxContentWidth, media.size.height),
              ),
              child: ClipRect(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      );
    }

    return content;
  }
}

extension ResponsiveContext on BuildContext {
  /// Scales a design value (font size, icon size, spacing) to this screen.
  double rs(double value) => value * Responsive.scale(this);

  double get gutter => Responsive.gutter(this);

  bool get isCompact => Responsive.isCompact(this);

  bool get isLandscape => Responsive.isLandscape(this);
}
