import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/orca_languages.dart';
import '../../models/user_role.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';

class FishermanRegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  final String selectedLanguage;
  final String onboardingToken;

  const FishermanRegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.selectedLanguage,
    required this.onboardingToken,
  });

  @override
  State<FishermanRegistrationScreen> createState() =>
      _FishermanRegistrationScreenState();
}

class _FishermanRegistrationScreenState
    extends State<FishermanRegistrationScreen> {
  final nameController = TextEditingController();
  final landingCentreController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    landingCentreController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  String get _languageCode {
    final matches = orcaLanguages.where(
      (language) => language.name == widget.selectedLanguage,
    );
    return matches.isEmpty ? 'en' : matches.first.code;
  }

  Future<void> _completeRegistration() async {
    if (nameController.text.trim().length < 2) {
      _message('Enter the fisherman name.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.completeFishermanRegistration(
        onboardingToken: widget.onboardingToken,
        fullName: nameController.text,
        preferredLanguage: _languageCode,
        homeLandingCentre: landingCentreController.text,
        emergencyContactName: emergencyNameController.text,
        emergencyContactPhone: emergencyPhoneController.text,
      );

      if (!mounted) return;

      if (result.user.role != 'FISHERMAN') {
        _message('ORCA returned an invalid account role.');
        return;
      }

      await SessionService.saveSession(
        accessToken: result.accessToken,
        user: result.user,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('ORCA profile created'),
            content: Text(
              'Your Fisher ID is:\n\n'
              '${result.user.fisherId ?? 'Generated successfully'}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Enter ORCA'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(role: UserRole.fisherman),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('Could not complete Fisherman registration.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }

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
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(child: PillProgress(value: 1)),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: OrcaMascot(
                    size: 100,
                    mood: MascotMood.happy,
                    halo: true,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Set up your\nORCA profile',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.limeSoft,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Phone verified: ${widget.phoneNumber}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    label: 'Full Name *',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: landingCentreController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    label: 'Home Landing Centre',
                    icon: Icons.place_outlined,
                    hint: 'Optional for now',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergencyNameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    label: 'Emergency Contact Name',
                    icon: Icons.contact_emergency_outlined,
                    hint: 'Optional for now',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergencyPhoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration(
                    label: 'Emergency Contact Number',
                    icon: Icons.phone_outlined,
                    hint: 'Optional for now',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.lavenderSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radius + 4),
                  ),
                  child: Row(
                    children: [
                      const SoftIcon(
                        Icons.language_rounded,
                        color: AppTheme.indigo,
                        background: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Preferred language: ${widget.selectedLanguage}\n'
                          'ORCA will store this preference with your account.',
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _completeRegistration,
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text('Create ORCA Fisher Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
