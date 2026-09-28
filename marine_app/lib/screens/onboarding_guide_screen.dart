import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/theme/app_theme.dart';
import '../data/orca_guide_content.dart';
import '../data/orca_languages.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';

class OnboardingGuideScreen extends StatefulWidget {
  final String initialLanguageCode;

  const OnboardingGuideScreen({super.key, this.initialLanguageCode = 'en'});

  @override
  State<OnboardingGuideScreen> createState() => _OnboardingGuideScreenState();
}

class _OnboardingGuideScreenState extends State<OnboardingGuideScreen> {
  final FlutterTts _tts = FlutterTts();

  late String selectedLanguageCode;
  int selectedRoleIndex = 0;
  int currentStep = 0;
  bool isSpeaking = false;

  GuideLocalePack get pack => getGuidePack(selectedLanguageCode);
  RoleGuideData get selectedGuide => pack.guides[selectedRoleIndex];
  GuideStepData get selectedStep => selectedGuide.steps[currentStep];

  OrcaLanguage get currentLanguage => orcaLanguages.firstWhere(
    (language) => language.code == selectedLanguageCode,
    orElse: () => orcaLanguages.first,
  );

  @override
  void initState() {
    super.initState();
    selectedLanguageCode = widget.initialLanguageCode;
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.44);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      if (mounted) setState(() => isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  Future<void> _speakCurrentStep() async {
    await _tts.stop();

    final available = await _tts.isLanguageAvailable(currentLanguage.ttsCode);
    if (available != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pack.voiceUnavailable)));
      return;
    }

    await _tts.setLanguage(currentLanguage.ttsCode);
    await _tts.speak(
      '${selectedGuide.title}. ${selectedStep.title}. ${selectedStep.description}',
    );
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => isSpeaking = false);
  }

  void _changeLanguage(String code) {
    _stopSpeaking();
    setState(() {
      selectedLanguageCode = code;
      selectedRoleIndex = 0;
      currentStep = 0;
    });
  }

  void _changeRole(int index) {
    _stopSpeaking();
    setState(() {
      selectedRoleIndex = index;
      currentStep = 0;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(selectedLanguageCode),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack.pageTitle,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 30,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pack.pageSubtitle,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 14.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _languageSelector(),
                      const SizedBox(height: 24),
                      Text(
                        pack.chooseGuide,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _roleSelector(),
                      const SizedBox(height: 26),
                      _roleOverview(),
                      const SizedBox(height: 20),
                      _currentStepCard(),
                      const SizedBox(height: 20),
                      _stepIndicators(),
                      const SizedBox(height: 24),
                      _navigationButtons(),
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

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: PillProgress(
              value: (currentStep + 1) / selectedGuide.steps.length,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.coralSoft,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: AppTheme.coralDeep,
                ),
                SizedBox(width: 5),
                Text(
                  'ORCA GUIDE',
                  style: TextStyle(
                    color: AppTheme.coralDeep,
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
    );
  }

  Widget _languageSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SoftIcon(
            Icons.language_rounded,
            color: AppTheme.indigo,
            background: AppTheme.lavenderSoft,
            size: 46,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedLanguageCode,
                borderRadius: BorderRadius.circular(18),
                items: orcaLanguages.map((language) {
                  return DropdownMenuItem(
                    value: language.code,
                    child: Text(
                      '${language.nativeName} • ${language.name}',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _changeLanguage(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pack.guides.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final guide = pack.guides[index];
          final selected = selectedRoleIndex == index;

          return GestureDetector(
            onTap: () => _changeRole(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 132,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected ? AppTheme.coral : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoftIcon(
                    guide.icon,
                    color: selected ? Colors.white : AppTheme.coralDeep,
                    background: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppTheme.coralSoft,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.ink,
                      fontSize: 11.5,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roleOverview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey('${selectedLanguageCode}_${selectedGuide.roleKey}'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lavenderSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            SoftIcon(
              selectedGuide.icon,
              color: AppTheme.indigo,
              background: Colors.white,
              size: 56,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedGuide.title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedGuide.subtitle,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const OrcaMascot(size: 58, mood: MascotMood.calm),
          ],
        ),
      ),
    );
  }

  Widget _currentStepCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(
          '${selectedLanguageCode}_${selectedRoleIndex}_$currentStep',
        ),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SoftIcon(
                  selectedStep.icon,
                  color: AppTheme.coralDeep,
                  background: AppTheme.coralSoft,
                  size: 52,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.limeSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pack.stepLabel} ${currentStep + 1}',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: OrcaMascot(
                size: 110,
                mood: MascotMood.values[currentStep % MascotMood.values.length],
                halo: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              selectedStep.title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selectedStep.description,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isSpeaking ? _stopSpeaking : _speakCurrentStep,
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_rounded,
                ),
                label: Text(
                  isSpeaking
                      ? pack.stopListening
                      : '${pack.listen} • ${currentLanguage.nativeName}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.coralDeep,
                  backgroundColor: AppTheme.coralSoft,
                  side: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(selectedGuide.steps.length, (index) {
        final selected = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? AppTheme.coral : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  Widget _navigationButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: currentStep == 0
                  ? null
                  : () {
                      _stopSpeaking();
                      setState(() => currentStep--);
                    },
              child: Text(pack.previous),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                _stopSpeaking();
                if (currentStep < selectedGuide.steps.length - 1) {
                  setState(() => currentStep++);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                currentStep == selectedGuide.steps.length - 1
                    ? pack.finishGuide
                    : pack.nextStep,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
