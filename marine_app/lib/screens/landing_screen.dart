import 'dart:async';

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme/app_theme.dart';
import '../widgets/motion.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';
import 'language_screen.dart';
import 'onboarding_guide_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _getStarted() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, _) => const LanguageScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openGuide() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OnboardingGuideScreen()));
  }

  /// Staggered entrance for hero elements, driven by one controller.
  Widget _enter(double start, Widget child, {double dy = 24}) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + 0.45).clamp(0, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, dy * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gutter;

    return Scaffold(
      body: GridBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero(g)),
            SliverToBoxAdapter(child: _sources(g)),
            SliverToBoxAdapter(child: _stats(g)),
            SliverToBoxAdapter(child: _challenge(g)),
            SliverToBoxAdapter(child: _capabilities(g)),
            SliverToBoxAdapter(child: _askOrca(g)),
            SliverToBoxAdapter(child: _agents(g)),
            SliverToBoxAdapter(child: _habitat(g)),
            SliverToBoxAdapter(child: _roles(g)),
            SliverToBoxAdapter(child: _trust(g)),
            SliverToBoxAdapter(child: _steps(g)),
            SliverToBoxAdapter(child: _finalCta(g)),
            SliverToBoxAdapter(child: _footer(g)),
          ],
        ),
      ),
    );
  }

  // ── 1. Hero ──────────────────────────────────────────────────────────────
  Widget _hero(double g) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(g - 6, 10, g - 6, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: ColoredBox(
            color: AppTheme.olive,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _enter(
                        0,
                        Row(
                          children: [
                            const OrcaMascot(size: 32, mood: MascotMood.calm),
                            const SizedBox(width: 8),
                            const Text(
                              'ORCA',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _getStarted,
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                              ),
                              child: const Text('Sign in'),
                            ),
                          ],
                        ),
                        dy: -12,
                      ),
                      const SizedBox(height: 18),
                      _enter(0.08, const _LivePill()),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: context.rs(150),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              right: 6,
                              top: 0,
                              child: _enter(
                                0.35,
                                const FloatY(
                                  child: OrcaMascot(
                                    size: 104,
                                    mood: MascotMood.happy,
                                    color: AppTheme.lavender,
                                  ),
                                ),
                                dy: 40,
                              ),
                            ),
                            Positioned.fill(
                              top: context.rs(40),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  children: [
                                    for (final (i, letter)
                                        in 'ORCA'.split('').indexed)
                                      _enter(
                                        0.12 + i * 0.07,
                                        Text(
                                          letter,
                                          style: const TextStyle(
                                            color: AppTheme.ink,
                                            fontSize: 140,
                                            height: 0.9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -4,
                                          ),
                                        ),
                                        dy: 60,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _enter(
                        0.4,
                        Text(
                          'Safer decisions at sea,\nbacked by evidence.',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: context.rs(27),
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _enter(
                        0.48,
                        const Text(
                          'ORCA brings live ocean forecasts, maritime boundaries, '
                          'seabed depth and a trained habitat model together with '
                          'specialised AI agents — turning them into clear, '
                          'multilingual guidance for fishermen, researchers and '
                          'coastal authorities.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _enter(
                        0.55,
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Tag(Icons.cloud_off_rounded, 'Offline-ready',
                                AppTheme.limeSoft),
                            _Tag(Icons.translate_rounded, '10 languages',
                                AppTheme.lavenderSoft),
                            _Tag(Icons.mic_none_rounded, 'Voice-first',
                                AppTheme.coralSoft),
                            _Tag(Icons.fact_check_outlined, 'Evidence-backed',
                                Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _enter(
                        0.62,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _getStarted,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Get started'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _enter(
                        0.68,
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openGuide,
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: const Text('How ORCA works'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.75),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                const AnimatedWaves(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 2. Data sources marquee ─────────────────────────────────────────────
  Widget _sources(double g) {
    const sources = [
      (Icons.waves_rounded, 'Open-Meteo Marine'),
      (Icons.air_rounded, 'Open-Meteo Weather'),
      (Icons.satellite_alt_rounded, 'INCOIS Ocean State Forecast'),
      (Icons.set_meal_outlined, 'INCOIS PFZ advisories'),
      (Icons.wind_power_rounded, 'INCOIS ASCAT winds'),
      (Icons.terrain_rounded, 'GEBCO bathymetry'),
      (Icons.biotech_outlined, 'CMLRE specimen records'),
      (Icons.gavel_rounded, 'Maritime zones · 12 nm & EEZ'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: g),
            child: const Text(
              'BUILT ON OPEN OCEAN SCIENCE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Marquee(
              children: [
                for (final (icon, label) in sources)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: AppTheme.coralDeep),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Stats ─────────────────────────────────────────────────────────────
  Widget _stats(double g) {
    const stats = [
      (10, '', 'Indian languages\nby text and voice'),
      (7, '', 'specialised AI\nagents'),
      (4, '', 'role-based\nworkspaces'),
      (792, '', 'verified records\ntrain the habitat model'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(g, 26, g, 0),
      child: Reveal(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                children: [
                  for (final (value, suffix, label) in stats)
                    SizedBox(
                      width: w,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CountUp(
                              value: value,
                              suffix: suffix,
                              style: TextStyle(
                                fontSize: context.rs(38),
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── 4. The challenge ─────────────────────────────────────────────────────
  Widget _challenge(double g) {
    const items = [
      (
        Icons.layers_outlined,
        'Fragmented information',
        'Forecasts, advisories, depth charts and boundary rules live in '
            'separate portals that are hard to combine before a trip.',
      ),
      (
        Icons.signal_cellular_connected_no_internet_0_bar_rounded,
        'No signal offshore',
        'Connectivity drops within a few nautical miles of the coast — '
            'exactly when guidance matters most.',
      ),
      (
        Icons.record_voice_over_outlined,
        'Language barriers',
        'Most marine information is published in English, while coastal '
            'communities speak many regional languages.',
      ),
      (
        Icons.border_outer_rounded,
        'Invisible boundaries',
        'Territorial-sea, EEZ and restricted-zone limits cannot be seen '
            'at sea, and crossing them has serious consequences.',
      ),
    ];

    return _Section(
      gutter: g,
      eyebrow: 'THE CHALLENGE',
      title: 'Going to sea should not depend on guesswork.',
      subtitle:
          'Small-scale fishers make high-stakes decisions every day with '
          'scattered, hard-to-read and often unreachable information.',
      child: Column(
        children: [
          for (final (i, (icon, title, text)) in items.indexed)
            Reveal(
              delay: Duration(milliseconds: 80 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InfoRow(
                  icon: icon,
                  title: title,
                  text: text,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 5. Capabilities ──────────────────────────────────────────────────────
  Widget _capabilities(double g) {
    const features = [
      (
        Icons.waves_rounded,
        'Sea Conditions',
        'Wave height, swell, wind and gusts for your exact location, with a '
            'clear safety screening.',
        AppTheme.coralSoft,
        AppTheme.coralDeep,
      ),
      (
        Icons.shield_outlined,
        'Boundary Guardian',
        'Checks your position against the 12 nm territorial sea, the EEZ and '
            'restricted zones.',
        AppTheme.lavenderSoft,
        AppTheme.indigo,
      ),
      (
        Icons.alt_route_rounded,
        'Weather-aware Routes',
        'Compares the fastest route with a lower-exposure alternative using '
            'forecast waves, wind and currents.',
        AppTheme.limeSoft,
        Color(0xFF3F8F66),
      ),
      (
        Icons.my_location_rounded,
        'Live Mission Tracking',
        'GPS progress, next-waypoint bearing, ETA and off-route alerts while '
            'you are at sea.',
        Color(0xFFFFF6E0),
        Color(0xFFB7791F),
      ),
      (
        Icons.download_for_offline_outlined,
        'Offline Mission Pack',
        'Route, zones, hazards and forecasts saved to the phone before you '
            'leave the harbour.',
        AppTheme.mint,
        AppTheme.charcoal,
      ),
      (
        Icons.mic_none_rounded,
        'Ask ORCA',
        'Ask by voice or text in your language and get a decision, the '
            'reason and one clear action.',
        AppTheme.coralSoft,
        AppTheme.coralDeep,
      ),
    ];

    return _Section(
      gutter: g,
      eyebrow: 'WHAT ORCA DOES',
      title: 'Everything a fishing trip needs, in one app.',
      subtitle:
          'From checking the sea at dawn to returning safely — each tool is '
          'designed for use on a small screen, in bright sun, with one hand.',
      child: LayoutBuilder(
        builder: (context, c) {
          final twoUp = c.maxWidth >= 440;
          final w = twoUp ? (c.maxWidth - 10) / 2 : c.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, (icon, title, text, bg, fg)) in features.indexed)
                SizedBox(
                  width: w,
                  child: Reveal(
                    delay: Duration(milliseconds: 70 * (i % 2)),
                    child: _FeatureTile(
                      icon: icon,
                      title: title,
                      text: text,
                      background: bg,
                      color: fg,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── 6. Ask ORCA live demo ────────────────────────────────────────────────
  Widget _askOrca(double g) {
    return _Section(
      gutter: g,
      tint: AppTheme.lavenderSoft,
      eyebrow: 'ASK ORCA',
      title: 'A decision, a reason and one action.',
      subtitle:
          'Ask in your own words — ORCA answers in the same language and '
          'reads the answer aloud. Every reply shows the evidence behind it.',
      child: const Reveal(child: _ChatDemo()),
    );
  }

  // ── 7. Agent pipeline ────────────────────────────────────────────────────
  Widget _agents(double g) {
    return _Section(
      gutter: g,
      eyebrow: 'HOW ORCA THINKS',
      title: 'Specialised agents, not one guessing model.',
      subtitle:
          'Each question passes through a chain of focused agents. Scientific '
          'calculations and GIS checks are deterministic; language models '
          'only explain the result.',
      child: const Reveal(child: _AgentPipeline()),
    );
  }

  // ── 8. Habitat intelligence ──────────────────────────────────────────────
  Widget _habitat(double g) {
    const features = [
      'Sea-surface temperature',
      'Temperature anomaly',
      'Chlorophyll-a',
      'Surface wind',
      'Depth',
      'Seabed slope',
      'Seasonality',
    ];

    return _Section(
      gutter: g,
      tint: AppTheme.limeSoft,
      eyebrow: 'HABITAT INTELLIGENCE',
      title: 'A trained model for fish-habitat opportunity.',
      subtitle:
          'ORCA scores habitat opportunity from live ocean conditions using a '
          'model trained on real biological survey data from Indian waters.',
      child: Reveal(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FactRow(
                Icons.biotech_outlined,
                'Training data',
                'CMLRE voucher-specimen records, 2011 – 2018',
              ),
              const _FactRow(
                Icons.public_rounded,
                'Coverage',
                'Indian seas, 5° – 25° N and 65° – 98° E',
              ),
              const _FactRow(
                Icons.account_tree_outlined,
                'Model',
                'Gradient-boosted trees, compared against logistic '
                    'regression and random forest',
              ),
              const _FactRow(
                Icons.event_available_outlined,
                'Validation',
                'Tested on an independent 2016 – 2018 period it never saw '
                    'during training',
              ),
              const SizedBox(height: 6),
              const Text(
                'INPUT FEATURES',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in features)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.canvas,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E0),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFFB7791F),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Research prototype. Scores are shown with confidence '
                        'and data freshness, and are never presented as a '
                        'guaranteed catch.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 9. Roles ─────────────────────────────────────────────────────────────
  Widget _roles(double g) {
    return _Section(
      gutter: g,
      eyebrow: 'ONE PLATFORM, FOUR WORKSPACES',
      title: 'Built around the people who use it.',
      subtitle:
          'Each role signs in to a workspace designed for its own task, '
          'with secure role-based access.',
      child: const Reveal(child: _RoleTabs()),
    );
  }

  // ── 10. Trust ────────────────────────────────────────────────────────────
  Widget _trust(double g) {
    const items = [
      (
        Icons.fact_check_outlined,
        'Evidence on every answer',
        'Each recommendation lists the data sources and tools that produced it.',
        AppTheme.coral,
      ),
      (
        Icons.schedule_rounded,
        'Freshness and validity',
        'Forecast age and validity are shown, so stale data is never mistaken '
            'for current conditions.',
        AppTheme.indigo,
      ),
      (
        Icons.do_not_disturb_on_outlined,
        'Abstains when unsure',
        'When safety data is missing or outdated, ORCA says so instead of '
            'inventing a confident answer.',
        AppTheme.charcoal,
      ),
      (
        Icons.sailing_outlined,
        'Supports, never replaces',
        'ORCA assists decisions; official advisories, navigation equipment '
            'and seamanship always come first.',
        AppTheme.danger,
      ),
    ];

    return _Section(
      gutter: g,
      tint: AppTheme.coralSoft,
      eyebrow: 'SAFETY AND TRUST',
      title: 'Honest about what it knows — and what it does not.',
      subtitle:
          'At sea, an overconfident answer is more dangerous than no answer. '
          'ORCA is designed around that principle.',
      child: Column(
        children: [
          for (final (i, (icon, title, text, color)) in items.indexed)
            Reveal(
              delay: Duration(milliseconds: 80 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InfoRow(
                  icon: icon,
                  title: title,
                  text: text,
                  color: color,
                  translucent: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 11. Steps ─────────────────────────────────────────────────────────────
  Widget _steps(double g) {
    const steps = [
      ('Choose your language', 'Pick from 10 Indian languages. Voice follows it.'),
      ('Verify and set up', 'Sign in with your phone number and add your boat.'),
      ('Plan, go and return', 'Check the sea, plan a route and track your trip.'),
    ];

    return _Section(
      gutter: g,
      eyebrow: 'GET STARTED',
      title: 'Ready in three steps.',
      subtitle: 'No training needed. The guide explains every screen aloud.',
      child: Column(
        children: [
          for (final (i, (title, text)) in steps.indexed)
            Reveal(
              delay: Duration(milliseconds: 100 * i),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(width: 2, height: 34, color: AppTheme.line),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            text,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 12. Final call to action ─────────────────────────────────────────────
  Widget _finalCta(double g) {
    return Padding(
      padding: EdgeInsets.fromLTRB(g - 6, 8, g - 6, 0),
      child: Reveal(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            color: AppTheme.coral,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              const FloatY(
                child: OrcaMascot(
                  size: 96,
                  mood: MascotMood.sparkle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Plan your next trip\nwith confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.rs(26),
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose your language and role to open the workspace built '
                'for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.ink,
                  ),
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(double g) {
    return Padding(
      padding: EdgeInsets.fromLTRB(g, 26, g, 34),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OrcaMascot(size: 22, mood: MascotMood.calm),
              SizedBox(width: 6),
              Text(
                'ORCA',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Agentic marine intelligence for India’s coastal communities.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Building blocks
// ═════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final double gutter;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Color? tint;

  const _Section({
    required this.gutter,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final header = Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tint == null
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              eyebrow,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: context.rs(25),
              height: 1.14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, const SizedBox(height: 22), child],
    );

    if (tint == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(gutter, 42, gutter, 8),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter - 6, 30, gutter - 6, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(32),
        ),
        child: content,
      ),
    );
  }
}

class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 6 + 8 * _pulse.value,
                    height: 6 + 8 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success.withValues(
                        alpha: 0.35 * (1 - _pulse.value),
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'AGENTIC MARINE INTELLIGENCE',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Tag(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.ink),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final bool translucent;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    this.translucent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: translucent
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon, color: color, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color background;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 13,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FactRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon, color: const Color(0xFF3F8F66), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Looping example conversation with Ask ORCA.
class _ChatDemo extends StatefulWidget {
  const _ChatDemo();

  @override
  State<_ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<_ChatDemo> {
  Timer? _timer;
  int _stage = 0; // 0 question, 1 thinking, 2 answer

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _stage = 2;
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      setState(() => _stage = (_stage + 1) % 5);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAnswer = _stage >= 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: const BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: const Text(
                'Is it safe to go fishing tomorrow morning?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OrcaMascot(size: 30, mood: MascotMood.calm),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: showAnswer
                        ? const _DemoAnswer(key: ValueKey('answer'))
                        : Container(
                            key: const ValueKey('typing'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TypingDots(),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Checking waves, wind and zones…',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Example answer for illustration.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DemoAnswer extends StatelessWidget {
  const _DemoAnswer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, String label, String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppTheme.coralDeep),
              const SizedBox(width: 7),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$label  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12.8, height: 1.4),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'GO WITH CAUTION',
              style: TextStyle(
                color: Color(0xFFB7791F),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          line(
            Icons.waves_rounded,
            'Why',
            'Waves near 1.4 m; wind rises after 11:00.',
          ),
          line(
            Icons.flag_outlined,
            'Action',
            'Stay inside the territorial sea and return before noon.',
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _EvidenceChip('Marine forecast'),
              _EvidenceChip('Boundary check'),
              _EvidenceChip('Habitat model'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  final String text;

  const _EvidenceChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lavenderSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: AppTheme.indigo),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.indigo,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Agent chain with a highlight that travels step by step.
class _AgentPipeline extends StatefulWidget {
  const _AgentPipeline();

  @override
  State<_AgentPipeline> createState() => _AgentPipelineState();
}

class _AgentPipelineState extends State<_AgentPipeline>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    (
      Icons.psychology_alt_outlined,
      'Intent agent',
      'Understands what you are asking — safety, route, boundary or fish.',
    ),
    (
      Icons.translate_rounded,
      'Language agent',
      'Detects your language so the answer comes back in it.',
    ),
    (
      Icons.account_tree_outlined,
      'Planner agent',
      'Chooses which tools and models the question needs.',
    ),
    (
      Icons.handyman_outlined,
      'Domain tools',
      'Marine forecast, boundary and zone checks, habitat model.',
    ),
    (
      Icons.record_voice_over_outlined,
      'Explanation agent',
      'Turns the evidence into a decision, a reason and one action.',
    ),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final active = (_c.value * _steps.length).floor() % _steps.length;
        return Column(
          children: [
            for (final (i, (icon, title, text)) in _steps.indexed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: i == active ? AppTheme.coral : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: i == active
                              ? [
                                  BoxShadow(
                                    color: AppTheme.coral.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 21,
                          color: i == active ? Colors.white : AppTheme.charcoal,
                        ),
                      ),
                      if (i < _steps.length - 1)
                        Container(
                          width: 2,
                          height: 22,
                          color: i < active ? AppTheme.coral : AppTheme.line,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: i == active ? 1 : 0.6,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              text,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12.8,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Role selector with animated content switching.
class _RoleTabs extends StatefulWidget {
  const _RoleTabs();

  @override
  State<_RoleTabs> createState() => _RoleTabsState();
}

class _RoleTabsState extends State<_RoleTabs> {
  int _index = 0;

  static const _roles = [
    (
      Icons.sailing_rounded,
      'Fisherman',
      'Available now',
      AppTheme.coral,
      [
        'Phone sign-in with OTP and boat profiles',
        'Sea conditions and boundary checks',
        'Weather-aware routes and live tracking',
        'Offline mission packs and voice assistant',
      ],
    ),
    (
      Icons.science_outlined,
      'Researcher',
      'Early access',
      Color(0xFF3F8F66),
      [
        'Explore SST, chlorophyll, wind and depth layers',
        'Compare areas and seasons, spot anomalies',
        'Habitat-model outputs with full evidence',
        'Traceable, report-ready analysis',
      ],
    ),
    (
      Icons.health_and_safety_outlined,
      'Authority',
      'Early access',
      Color(0xFFE0962B),
      [
        'Coastal situational awareness',
        'Boundary and restricted-zone oversight',
        'Advisories and incident context',
        'Vessel and mission information',
      ],
    ),
    (
      Icons.admin_panel_settings_outlined,
      'Admin',
      'Early access',
      AppTheme.indigo,
      [
        'Role and account management',
        'Dataset freshness monitoring',
        'Model versions and health',
        'Agent execution and platform status',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (icon, name, status, color, points) = _roles[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, role) in _roles.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: i == _index ? AppTheme.ink : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            role.$1,
                            size: 16,
                            color: i == _index ? Colors.white : AppTheme.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            role.$2,
                            style: TextStyle(
                              color: i == _index ? Colors.white : AppTheme.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_index),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SoftIcon(icon, color: color, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final p in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 17, color: color),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 13.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
