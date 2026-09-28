import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: FadeTransition(
        opacity: _fade,
        child: GridBackground(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _hero()),
              SliverToBoxAdapter(child: _whyOrca()),
              SliverToBoxAdapter(child: _roles()),
              SliverToBoxAdapter(child: _agents()),
              SliverToBoxAdapter(child: _pipeline()),
              SliverToBoxAdapter(child: _trust()),
              SliverToBoxAdapter(child: _impact()),
              SliverToBoxAdapter(child: _research()),
              SliverToBoxAdapter(child: _finalCta()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero: big wordmark + mascot peeking, like the Talkie cover ──────────
  Widget _hero() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.olive,
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OrcaMascot(size: 34, mood: MascotMood.calm),
                  const SizedBox(width: 8),
                  const Text(
                    'orca',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _getStarted,
                    style: TextButton.styleFrom(foregroundColor: AppTheme.ink),
                    child: const Text('Log in'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 190,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      right: 18,
                      top: 0,
                      child: OrcaMascot(
                        size: 118,
                        mood: MascotMood.happy,
                        color: AppTheme.lavender,
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'ORCA',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 160,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -6,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 2,
                      top: 18,
                      child: StickerLabel('AGENTIC', angle: -10),
                    ),
                    Positioned(
                      right: 0,
                      bottom: -16,
                      child: Transform.rotate(
                        angle: 0.12,
                        child: const BubbleBadge(
                          'OFFLINE\nFIRST',
                          color: AppTheme.lime,
                          size: 70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Marine intelligence\nthat travels with you.',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 28,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'One platform for fishermen, marine researchers, coastal authorities and administrators — turning ocean, weather and geospatial data into explainable decisions.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroBadge(
                    icon: Icons.cloud_off_rounded,
                    text: 'Offline-first',
                    color: AppTheme.limeSoft,
                  ),
                  _HeroBadge(
                    icon: Icons.auto_awesome_rounded,
                    text: 'Agentic',
                    color: AppTheme.lavenderSoft,
                  ),
                  _HeroBadge(
                    icon: Icons.fact_check_outlined,
                    text: 'Evidence-backed',
                    color: Colors.white,
                  ),
                  _HeroBadge(
                    icon: Icons.translate_rounded,
                    text: 'Multilingual',
                    color: AppTheme.coralSoft,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getStarted,
                  child: const Text("Let's start"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openGuide,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('How ORCA works'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    side: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── "Why ORCA" block with big numbers, like "Why Talkie" ──────────────
  Widget _whyOrca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.lavenderSoft,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why\nORCA',
              style: TextStyle(
                fontSize: 56,
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.4,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Because the sea deserves\nmore than guesswork!',
              style: TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'ORCA coordinates satellite, ocean, weather and geospatial information through specialized agents, models and deterministic GIS tools.',
              style: TextStyle(color: AppTheme.muted, fontSize: 14.5, height: 1.5),
            ),
            SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _BigNumber('4', 'role-specific\nworkspaces')),
                Expanded(child: _BigNumber('1', 'shared intelligence\nlayer')),
              ],
            ),
            SizedBox(height: 18),
            _BigNumber('24/7', 'decision support when data is valid'),
          ],
        ),
      ),
    );
  }

  Widget _roles() {
    return _section(
      eyebrow: 'BUILT AROUND REAL USERS',
      title: 'One platform. Four operational views.',
      subtitle:
          'Each user gets a workflow designed for their actual task instead of a generic dashboard.',
      child: const Column(
        children: [
          _RoleCard(
            icon: Icons.phishing_rounded,
            title: 'Fisherman',
            text:
                'Simple sea conditions, safer trip planning, offline Mission Packs, Boundary Guardian and SOS support.',
            accent: AppTheme.coral,
          ),
          SizedBox(height: 10),
          _RoleCard(
            icon: Icons.science_rounded,
            title: 'Marine Researcher',
            text:
                'Scientific data layers, anomaly analysis, spatial-temporal comparison, productivity investigation and evidence-backed reporting.',
            accent: Color(0xFF3F8F66),
          ),
          SizedBox(height: 10),
          _RoleCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Coastal Authority / Rescue',
            text:
                'SOS command map, hazard awareness, incident lifecycle, advisories and geofence management.',
            accent: Color(0xFFE0962B),
          ),
          SizedBox(height: 10),
          _RoleCard(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Administrator',
            text:
                'Dataset freshness, model versions, agent execution, role management and platform health.',
            accent: AppTheme.indigo,
          ),
        ],
      ),
    );
  }

  Widget _agents() {
    return _section(
      tint: AppTheme.coralSoft,
      eyebrow: 'HOW ORCA THINKS',
      title: 'From fragmented data to one explainable decision layer.',
      subtitle:
          'Specialized agents, models and GIS tools work together — each doing what it does best.',
      child: const Column(
        children: [
          _TintFeature(
            icon: Icons.hub_rounded,
            title: 'Agentic coordination',
            text:
                'A planner selects the right marine tools, datasets and domain models for the task instead of forcing every problem through one model.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.map_outlined,
            title: 'Geospatial reasoning',
            text:
                'Routes, boundaries, restricted zones, hazards and spatial relationships are handled with GIS logic rather than language-model guesswork.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.fact_check_outlined,
            title: 'Explainable outcomes',
            text:
                'Recommendations can carry evidence, freshness, validity and confidence so users understand why ORCA reached a conclusion.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.translate_rounded,
            title: 'Language-first usability',
            text:
                'Role guides can be read and spoken in regional languages so marine intelligence is easier to understand.',
          ),
        ],
      ),
    );
  }

  Widget _pipeline() {
    return _section(
      eyebrow: 'DATA → REASONING → ACTION',
      title: 'A marine intelligence pipeline, not just a chatbot.',
      subtitle:
          'ORCA separates scientific calculation from natural-language explanation.',
      child: const Column(
        children: [
          _PipelineCard(
            number: '01',
            color: AppTheme.lime,
            title: 'Marine data',
            text:
                'SST, chlorophyll-a, waves and swell, wind, currents, tides, bathymetry, PFZ history, weather alerts and geospatial boundaries.',
          ),
          SizedBox(height: 10),
          _PipelineCard(
            number: '02',
            color: AppTheme.lavender,
            title: 'Domain intelligence',
            text:
                'PFZ models, risk logic, anomaly detection, route optimization, geofencing and mission simulation.',
          ),
          SizedBox(height: 10),
          _PipelineCard(
            number: '03',
            color: AppTheme.butter,
            title: 'Agent collaboration',
            text:
                'Specialized agents discover data, plan tool use, combine evidence and prepare role-specific outcomes.',
          ),
          SizedBox(height: 10),
          _PipelineCard(
            number: '04',
            color: AppTheme.coralSoft,
            title: 'Human decision support',
            text:
                'Maps, charts, routes, alerts, advisories, reports and multilingual explanations designed for the user in front of ORCA.',
          ),
        ],
      ),
    );
  }

  Widget _trust() {
    return _section(
      eyebrow: 'OFFLINE-FIRST + TRUST',
      title: 'Designed for the moment connectivity disappears.',
      subtitle:
          'ORCA should not assume reliable offshore connectivity, and it should never hide uncertainty.',
      child: const Column(
        children: [
          _LightFeature(
            icon: Icons.download_for_offline_rounded,
            color: AppTheme.coral,
            title: 'Sea Mission Pack',
            text:
                'Carry route geometry, offline map, hazards, geofences, forecast layers and evidence needed for a planned mission.',
          ),
          SizedBox(height: 10),
          _LightFeature(
            icon: Icons.schedule_rounded,
            color: AppTheme.indigo,
            title: 'Freshness and validity',
            text:
                'Users can see when data was updated and whether a forecast is still valid for the decision being made.',
          ),
          SizedBox(height: 10),
          _LightFeature(
            icon: Icons.block_rounded,
            color: AppTheme.charcoal,
            title: 'Abstain when evidence is weak',
            text:
                'When safety data is too stale or unavailable, ORCA should say so instead of manufacturing a confident answer.',
          ),
          SizedBox(height: 10),
          _LightFeature(
            icon: Icons.sos_rounded,
            color: AppTheme.danger,
            title: 'Honest SOS status',
            text:
                'ORCA distinguishes sent, acknowledged and not-transmitted states instead of claiming help is on the way without confirmation.',
          ),
        ],
      ),
    );
  }

  Widget _impact() {
    return _section(
      tint: AppTheme.limeSoft,
      eyebrow: 'BENEFITS & IMPACT',
      title: 'Different users. Shared situational awareness.',
      subtitle:
          'The value is better continuity, clearer evidence and faster access to the information each role needs.',
      child: const Column(
        children: [
          _TintFeature(
            icon: Icons.sailing_rounded,
            title: 'Safer operational decisions',
            text:
                'Fishermen can combine sea conditions, route risk, boundaries and alerts before and during a mission.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.biotech_rounded,
            title: 'Stronger marine analysis',
            text:
                'Researchers can connect multiple ocean variables, compare periods and produce traceable evidence rather than working from isolated layers.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.emergency_share_rounded,
            title: 'Better emergency context',
            text:
                'Authorities receive incident coordinates together with vessel and mission context, improving shared situational awareness.',
          ),
          SizedBox(height: 10),
          _TintFeature(
            icon: Icons.sync_rounded,
            title: 'Operational continuity',
            text:
                'Offline mission intelligence reduces the gap between shore-side planning and at-sea use when connectivity is limited.',
          ),
        ],
      ),
    );
  }

  Widget _research() {
    return _section(
      eyebrow: 'RESEARCH DEPTH',
      title: 'Professional tools for marine investigation.',
      subtitle:
          'The researcher experience is deliberately deeper and more technical than the fisherman workflow.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.softShadow,
        ),
        child: const Column(
          children: [
            _ResearchItem(
              number: '1',
              title: 'Data Explorer',
              text:
                  'SST, chlorophyll-a, waves/swell, wind, currents, tides, bathymetry and PFZ history.',
            ),
            SizedBox(height: 16),
            _ResearchItem(
              number: '2',
              title: 'Spatial + temporal analysis',
              text:
                  'Compare areas, dates, seasonal baselines and anomalies across marine variables.',
            ),
            SizedBox(height: 16),
            _ResearchItem(
              number: '3',
              title: 'Productivity Investigator',
              text:
                  'Study environmental relationships while avoiding unsupported biological causation without catch or CPUE data.',
            ),
            SizedBox(height: 16),
            _ResearchItem(
              number: '4',
              title: 'Evidence + reporting',
              text:
                  'Use provenance, freshness, confidence, maps and charts to create traceable research outputs.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _finalCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.mint,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            const OrcaMascot(size: 110, mood: MascotMood.sparkle, halo: true),
            const SizedBox(height: 16),
            const Text(
              'WOW! Ready to dive in?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose your language, select your role and continue into the workflow designed for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _getStarted,
                child: const Text('Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
    Color? tint,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tint == null ? Colors.white : Colors.white.withValues(alpha: 0.7),
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
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 27,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 14.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );

    if (tint == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 44, 22, 36),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(32),
        ),
        child: content,
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  final String label;

  const _BigNumber(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 52,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.3),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.ink, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon, color: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
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

class _TintFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TintFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.ink,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
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

class _LightFeature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _LightFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon, color: color, size: 48),
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

class _PipelineCard extends StatelessWidget {
  final String number;
  final Color color;
  final String title;
  final String text;

  const _PipelineCard({
    required this.number,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
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

class _ResearchItem extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _ResearchItem({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.sage,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
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
      ],
    );
  }
}
