import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/orca_l10n.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';
import 'auth/admin_login_screen.dart';
import 'auth/authority_login_screen.dart';
import 'auth/fisherman_phone_auth_screen.dart';
import 'auth/researcher_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String selectedLanguage;

  const RoleSelectionScreen({super.key, required this.selectedLanguage});

  String get lang => OrcaL10n.codeFromSelection(selectedLanguage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(child: PillProgress(value: 0.66)),
                    const SizedBox(width: 12),
                    const Text(
                      '2/3',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Center(
                  child: OrcaMascot(
                    size: 110,
                    mood: MascotMood.sparkle,
                    halo: true,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  OrcaL10n.t(lang, 'choose_role'),
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  OrcaL10n.t(lang, 'choose_role_sub'),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                _roleCard(
                  icon: Icons.sailing_rounded,
                  title: OrcaL10n.t(lang, 'fisherman'),
                  description: OrcaL10n.t(lang, 'fisherman_desc'),
                  accent: AppTheme.coral,
                  highlight: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FishermanPhoneAuthScreen(
                          selectedLanguage: selectedLanguage,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _roleCard(
                  icon: Icons.science_rounded,
                  title: OrcaL10n.t(lang, 'researcher'),
                  description: OrcaL10n.t(lang, 'researcher_desc'),
                  accent: const Color(0xFF3F8F66),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResearcherLoginScreen(
                          selectedLanguage: selectedLanguage,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _roleCard(
                  icon: Icons.health_and_safety_rounded,
                  title: OrcaL10n.t(lang, 'authority'),
                  description: OrcaL10n.t(lang, 'authority_desc'),
                  accent: const Color(0xFFE0962B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthorityLoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _roleCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: OrcaL10n.t(lang, 'admin'),
                  description: OrcaL10n.t(lang, 'admin_desc'),
                  accent: AppTheme.indigo,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminLoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final fg = highlight ? Colors.white : AppTheme.ink;
    final sub = highlight
        ? Colors.white.withValues(alpha: 0.85)
        : AppTheme.muted;

    return Material(
      color: highlight ? AppTheme.coral : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SoftIcon(
                icon,
                color: highlight ? Colors.white : accent,
                background: highlight
                    ? Colors.white.withValues(alpha: 0.22)
                    : null,
                size: 50,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(color: sub, fontSize: 12.8, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: sub),
            ],
          ),
        ),
      ),
    );
  }
}
