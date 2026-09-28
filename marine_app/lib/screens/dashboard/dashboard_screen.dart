import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../data/orca_l10n.dart';
import '../../services/fisherman_service.dart';
import '../../services/session_service.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/marine_status_card.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import '../profile/fisherman_profile_screen.dart';
import '../marine/sea_conditions_screen.dart';
import '../orca/ask_orca_screen.dart';
import '../splash_screen.dart';
import '../vessel/vessel_form_screen.dart';
import '../vessel/vessel_list_screen.dart';
import '../gis/boundary_guardian_screen.dart';
import '../gis/plan_trip_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserRole role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool checkingVessels = false;
  bool hasVessel = true;
  bool hideVesselPrompt = false;
  String lang = 'en';

  UserRole get role => widget.role;

  String tr(String key) => OrcaL10n.t(lang, key);

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    if (role == UserRole.fisherman) {
      _refreshVessels();
    }
  }

  Future<void> _loadLanguage() async {
    final cached = await SessionService.getPreferredLanguage();

    String resolved = cached ?? 'en';

    if (role == UserRole.fisherman) {
      try {
        final profile = await FishermanService.getProfile();
        resolved = profile.preferredLanguage;
        await SessionService.setPreferredLanguage(resolved);
      } catch (_) {
        // Cached language remains usable offline.
      }
    }

    if (mounted) {
      setState(() {
        lang = OrcaL10n.codeFromSelection(resolved);
      });
    }
  }

  Future<void> _refreshVessels() async {
    if (!mounted) return;
    setState(() => checkingVessels = true);

    try {
      final vessels = await FishermanService.getVessels();
      if (!mounted) return;
      setState(() {
        hasVessel = vessels.isNotEmpty;
        if (hasVessel) hideVesselPrompt = false;
      });
    } catch (_) {
      // Do not block the offline-first dashboard if the API is unavailable.
    } finally {
      if (mounted) setState(() => checkingVessels = false);
    }
  }

  void comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$feature will be connected in the next development phase.',
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('logout_title')),
        content: Text(tr('logout_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('logout')),
          ),
        ],
      ),
    );

    if (yes != true) return;

    await SessionService.clear();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FishermanProfileScreen()));
    if (mounted) {
      await _loadLanguage();
      await _refreshVessels();
    }
  }

  Future<void> _openVessels() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const VesselListScreen()));
    if (mounted) await _refreshVessels();
  }

  Future<void> _setupBoat() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const VesselFormScreen()));
    if (changed == true && mounted) {
      await _refreshVessels();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.fisherman:
        return _fisherman(context);
      case UserRole.researcher:
        return _researcher(context);
      case UserRole.authority:
        return _authority(context);
      case UserRole.admin:
        return _admin(context);
    }
  }

  Widget _fisherman(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshVessels,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 124),
              children: [
                _topBar(
                  context,
                  title: tr('good_morning'),
                  subtitle: tr('ready_mission'),
                ),
                const SizedBox(height: 18),
                _hero(),
                const SizedBox(height: 18),
                const MarineStatusCard(),
                if (!checkingVessels && !hasVessel && !hideVesselPrompt) ...[
                  const SizedBox(height: 18),
                  _boatSetupCard(),
                ],
                const SizedBox(height: 26),
                _sectionTitle(tr('ask_orca'), tr('assistant_sub')),
                const SizedBox(height: 12),
                _assistantCard(context),
                const SizedBox(height: 28),
                _sectionTitle(tr('mission_tools'), tr('mission_tools_sub')),
                const SizedBox(height: 12),
                _quickGrid(context, [
                  _QuickAction(
                    tr('plan_trip'),
                    Icons.route_rounded,
                    AppTheme.coralDeep,
                    actionId: 'plan_trip',
                  ),
                  _QuickAction(
                    tr('sea_conditions'),
                    Icons.water_rounded,
                    AppTheme.cyan,
                    actionId: 'sea_conditions',
                  ),
                  _QuickAction(
                    tr('alerts'),
                    Icons.warning_amber_rounded,
                    AppTheme.warning,
                  ),
                  _QuickAction(
                    tr('offline_mission'),
                    Icons.offline_pin_rounded,
                    Color(0xFF4B46E0),
                  ),
                ]),
                const SizedBox(height: 28),
                _sectionTitle(tr('safety'), tr('safety_sub')),
                const SizedBox(height: 12),
                FeatureCard(
                  title: tr('boundary_guardian'),
                  subtitle: tr('boundary_desc'),
                  icon: Icons.public_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BoundaryGuardianScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  title: tr('mission_simulation'),
                  subtitle: tr('simulation_desc'),
                  icon: Icons.timeline_rounded,
                  onTap: () => comingSoon(context, 'Mission Simulation'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: FloatingActionButton.extended(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius + 2),
            ),
            onPressed: () => comingSoon(context, 'Emergency SOS'),
            icon: const Icon(Icons.sos_rounded, size: 28),
            label: Text(
              tr('emergency_sos'),
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.limeSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          const SoftIcon(
            Icons.sailing_rounded,
            color: AppTheme.ink,
            background: AppTheme.lime,
            size: 50,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('offline_copilot'),
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  tr('offline_copilot_desc'),
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12.5,
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

  Widget _boatSetupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.butter.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIcon(
                Icons.directions_boat_filled_rounded,
                color: AppTheme.ink,
                background: Colors.white,
                size: 42,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('setup_boat'),
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const OrcaMascot(size: 44, mood: MascotMood.sleepy),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            tr('setup_boat_desc'),
            style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _setupBoat,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(tr('add_now')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => hideVesselPrompt = true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(tr('skip_now')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assistantCard(BuildContext context) {
    return Material(
      color: AppTheme.lavenderSoft,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AskOrcaScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const OrcaMascot(size: 58, mood: MascotMood.happy),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('ask_anything'),
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      tr('ask_desc'),
                      style: TextStyle(color: AppTheme.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.indigo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _researcher(BuildContext context) {
    return _standardDashboard(
      context,
      heading: tr('research_heading'),
      subtitle: 'Explore environmental conditions and historical patterns.',
      features: [
        FeatureCard(
          title: 'Ask ORCA Research',
          subtitle: 'Explore marine datasets using natural language.',
          icon: Icons.auto_awesome_rounded,
          onTap: () => comingSoon(context, 'Research Assistant'),
        ),
        FeatureCard(
          title: 'Data Explorer',
          subtitle: 'Analyze SST, chlorophyll, currents and waves.',
          icon: Icons.layers_rounded,
          onTap: () => comingSoon(context, 'Data Explorer'),
        ),
        FeatureCard(
          title: 'Productivity Investigator',
          subtitle: 'Investigate environmental changes over time.',
          icon: Icons.analytics_rounded,
          onTap: () => comingSoon(context, 'Productivity Investigator'),
        ),
        FeatureCard(
          title: 'Anomaly Detection',
          subtitle: 'Detect unusual marine environmental conditions.',
          icon: Icons.show_chart_rounded,
          onTap: () => comingSoon(context, 'Anomaly Detection'),
        ),
        FeatureCard(
          title: 'Reports',
          subtitle: 'Generate evidence-backed marine analysis.',
          icon: Icons.description_rounded,
          onTap: () => comingSoon(context, 'Reports'),
        ),
      ],
    );
  }

  Widget _authority(BuildContext context) {
    return _standardDashboard(
      context,
      heading: tr('authority_heading'),
      subtitle: 'Monitor hazards and respond to emergencies.',
      features: [
        FeatureCard(
          title: 'Active SOS',
          subtitle: 'View incoming fisherman emergency incidents.',
          icon: Icons.sos_rounded,
          color: AppTheme.danger,
          onTap: () => comingSoon(context, 'SOS Command Centre'),
        ),
        FeatureCard(
          title: 'Hazard Map',
          subtitle: 'Monitor waves, weather and hazardous zones.',
          icon: Icons.map_rounded,
          onTap: () => comingSoon(context, 'Hazard Map'),
        ),
        FeatureCard(
          title: 'Marine Alerts',
          subtitle: 'Review active advisories and safety warnings.',
          icon: Icons.warning_rounded,
          color: AppTheme.warning,
          onTap: () => comingSoon(context, 'Marine Alerts'),
        ),
        FeatureCard(
          title: 'Geofences',
          subtitle: 'Manage restricted and operational areas.',
          icon: Icons.fence_rounded,
          onTap: () => comingSoon(context, 'Geofences'),
        ),
        FeatureCard(
          title: 'Incident History',
          subtitle: 'Review previous emergency incidents.',
          icon: Icons.history_rounded,
          onTap: () => comingSoon(context, 'Incident History'),
        ),
      ],
    );
  }

  Widget _admin(BuildContext context) {
    return _standardDashboard(
      context,
      heading: tr('admin_heading'),
      subtitle: 'System monitoring and platform management.',
      features: [
        FeatureCard(
          title: 'Dataset Health',
          subtitle: 'Monitor dataset freshness and ingestion.',
          icon: Icons.storage_rounded,
          onTap: () => comingSoon(context, 'Dataset Health'),
        ),
        FeatureCard(
          title: 'Model Registry',
          subtitle: 'Review deployed model versions and metrics.',
          icon: Icons.psychology_rounded,
          onTap: () => comingSoon(context, 'Model Registry'),
        ),
        FeatureCard(
          title: 'Agent Monitoring',
          subtitle: 'Inspect agent tasks and execution status.',
          icon: Icons.hub_rounded,
          onTap: () => comingSoon(context, 'Agent Monitoring'),
        ),
        FeatureCard(
          title: 'System Health',
          subtitle: 'Monitor backend and database services.',
          icon: Icons.monitor_heart_rounded,
          onTap: () => comingSoon(context, 'System Health'),
        ),
      ],
    );
  }

  Widget _standardDashboard(
    BuildContext context, {
    required String heading,
    required String subtitle,
    required List<Widget> features,
  }) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: features.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _topBar(context, title: heading, subtitle: subtitle),
                );
              }
              return features[index - 1];
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        const OrcaMascot(size: 50, mood: MascotMood.sparkle, halo: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onSelected: (value) async {
            if (value == 'profile') {
              await _openProfile();
            } else if (value == 'vessels') {
              await _openVessels();
            } else if (value == 'language') {
              // Preferred language is currently stored in the
              // authenticated Fisherman profile.
              await _openProfile();
            } else if (value == 'logout') {
              if (context.mounted) await _logout(context);
            }
          },
          itemBuilder: (_) => [
            if (role == UserRole.fisherman) ...[
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded),
                    SizedBox(width: 10),
                    Text(tr('my_profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'vessels',
                child: Row(
                  children: [
                    const Icon(Icons.sailing_rounded),
                    SizedBox(width: 10),
                    Text(tr('my_vessels')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded),
                    SizedBox(width: 10),
                    Text(tr('language')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.danger),
                  SizedBox(width: 10),
                  Text(
                    tr('logout'),
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: const SoftIcon(
            Icons.person_rounded,
            color: AppTheme.ink,
            background: Colors.white,
            size: 46,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _quickGrid(BuildContext context, List<_QuickAction> actions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        const tints = [
          AppTheme.coralSoft,
          AppTheme.lavenderSoft,
          Color(0xFFFBF3CF),
          AppTheme.limeSoft,
        ];

        return Material(
          color: tints[index % tints.length],
          borderRadius: BorderRadius.circular(AppTheme.radiusLg - 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg - 2),
            onTap: () {
              if (action.actionId == 'sea_conditions') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeaConditionsScreen(),
                  ),
                );
                return;
              }

              if (action.actionId == 'plan_trip') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanTripScreen()),
                );
                return;
              }

              comingSoon(context, action.title);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftIcon(
                    action.icon,
                    color: action.color,
                    background: Colors.white,
                    size: 44,
                  ),
                  const Spacer(),
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String? actionId;

  const _QuickAction(this.title, this.icon, this.color, {this.actionId});
}
