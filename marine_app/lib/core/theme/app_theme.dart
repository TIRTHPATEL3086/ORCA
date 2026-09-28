import 'package:flutter/material.dart';

/// ORCA design system, inspired by the Talkie app style:
/// soft mint canvas, coral hero colour, charcoal-green primary buttons,
/// playful lavender / lime / butter accents and clean SF-Pro-like type (Inter).
class AppTheme {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color coral = Color(0xFFEC7462);
  static const Color coralDeep = Color(0xFFD65A48);
  static const Color coralSoft = Color(0xFFFCE4DF);

  static const Color indigo = Color(0xFF4B46E0);
  static const Color lavender = Color(0xFFC3BAF0);
  static const Color lavenderSoft = Color(0xFFEDEAFC);
  static const Color lime = Color(0xFFE3F57A);
  static const Color limeSoft = Color(0xFFF3F9D0);
  static const Color butter = Color(0xFFF6E48A);
  static const Color sage = Color(0xFFD6E5D6);
  static const Color sageDeep = Color(0xFF8FB29A);
  static const Color olive = Color(0xFFEEF1DC);

  // ── Neutrals ───────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1D2520);
  static const Color charcoal = Color(0xFF59625B);
  static const Color muted = Color(0xFF6E7A72);
  static const Color hint = Color(0xFF9AA59D);
  static const Color line = Color(0xFFDCE6DA);
  static const Color canvas = Color(0xFFEDF3EC);
  static const Color mint = Color(0xFFE3EEE2);
  static const Color surface = Colors.white;

  // ── Status ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3F9F6B);
  static const Color warning = Color(0xFFF0A93A);
  static const Color danger = Color(0xFFE5484D);

  // ── Legacy names (kept so every screen picks up the new palette) ───────
  static const Color navy = ink;
  static const Color oceanBlue = coral;
  static const Color cyan = indigo;
  static const Color background = canvas;

  // ── Shape ──────────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radius = 16;
  static const double radiusLg = 24;

  static const String fontFamily = 'Inter';

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: coral,
      primary: coral,
      onPrimary: Colors.white,
      primaryContainer: coralSoft,
      onPrimaryContainer: coralDeep,
      secondary: charcoal,
      onSecondary: Colors.white,
      secondaryContainer: sage,
      onSecondaryContainer: ink,
      tertiary: indigo,
      tertiaryContainer: lavenderSoft,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
      error: danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
        bodySmall: text.bodySmall?.copyWith(color: muted, height: 1.4),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: const TextStyle(color: hint, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(
          color: charcoal,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(coral, 1.6),
        errorBorder: border(danger),
        focusedErrorBorder: border(danger, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: sage,
          disabledForegroundColor: hint,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: sage,
          disabledForegroundColor: hint,
          minimumSize: const Size(64, 52),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: const BorderSide(color: line),
          minimumSize: const Size(64, 52),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: coralDeep,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: coral,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: coral,
        disabledColor: mint,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surface,
          selectedBackgroundColor: coral,
          selectedForegroundColor: Colors.white,
          foregroundColor: ink,
          side: const BorderSide(color: line),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: coral,
        linearTrackColor: sage,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? coral : sage,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? coral : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? coral : hint,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: coral,
        inactiveTrackColor: sage,
        thumbColor: coral,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: charcoal,
        textColor: ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: coralSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? coralDeep : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight:
                s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: sageDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: muted,
        indicatorColor: coral,
        dividerColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
