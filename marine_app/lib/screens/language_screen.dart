import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';
import 'role_selection_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'English';

  final List<_LanguageOption> languages = const [
    _LanguageOption('English', 'English', 'EN'),
    _LanguageOption('Hindi', 'हिन्दी', 'HI'),
    _LanguageOption('Gujarati', 'ગુજરાતી', 'GU'),
    _LanguageOption('Marathi', 'मराठी', 'MR'),
    _LanguageOption('Telugu', 'తెలుగు', 'TE'),
    _LanguageOption('Tamil', 'தமிழ்', 'TA'),
    _LanguageOption('Kannada', 'ಕನ್ನಡ', 'KN'),
    _LanguageOption('Malayalam', 'മലയാളം', 'ML'),
    _LanguageOption('Bengali', 'বাংলা', 'BN'),
    _LanguageOption('Odia', 'ଓଡ଼ିଆ', 'OR'),
  ];

  void _continue() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return RoleSelectionScreen(selectedLanguage: selectedLanguage);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(child: PillProgress(value: 0.33)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lavenderSoft,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 15,
                            color: AppTheme.indigo,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'LANGUAGE',
                            style: TextStyle(
                              color: AppTheme.indigo,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Choose your\nlanguage',
                              style: TextStyle(
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          OrcaMascot(size: 78, mood: MascotMood.sparkle),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Choose the language you understand best. '
                        'ORCA will use it across guidance, alerts '
                        'and marine information.',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: languages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final language = languages[index];

                            final isSelected =
                                selectedLanguage == language.name;

                            return _LanguageCard(
                              language: language,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedLanguage = language.name;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.limeSoft,
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                        child: const Row(
                          children: [
                            SoftIcon(
                              Icons.volume_up_rounded,
                              color: AppTheme.ink,
                              background: AppTheme.lime,
                              size: 36,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Voice guidance will also follow '
                                'your selected language.',
                                style: TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      ElevatedButton(
                        onPressed: _continue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue in $selectedLanguage'),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 54,
      decoration: BoxDecoration(
        color: selected ? AppTheme.coral : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppTheme.coralSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    language.code,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.coralDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    language.nativeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String name;
  final String nativeName;
  final String code;

  const _LanguageOption(this.name, this.nativeName, this.code);
}
