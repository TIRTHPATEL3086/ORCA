import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _bounce,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      0,
                      -10 * Curves.easeInOut.transform(_bounce.value),
                    ),
                    child: child,
                  ),
                  child: const OrcaMascot(size: 150),
                ),
                const SizedBox(height: 26),
                const Text(
                  'ORCA',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                const StickerLabel('MARINE INTELLIGENCE', angle: -4),
                const Spacer(flex: 3),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: AppTheme.coral,
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Intelligence that travels with you.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13.5),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
