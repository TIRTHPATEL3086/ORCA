import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/orca_languages.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedLanguage;

  const RegisterScreen({super.key, required this.selectedLanguage});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  String get _languageCode {
    final matches = orcaLanguages.where(
      (language) => language.name == widget.selectedLanguage,
    );
    return matches.isEmpty ? 'en' : matches.first.code;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.length < 2) {
      _message('Enter your full name.');
      return;
    }

    if (!email.contains('@')) {
      _message('Enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      _message('Password must contain at least 8 characters.');
      return;
    }

    if (password != confirmPasswordController.text) {
      _message('Passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.registerResearcher(
        fullName: name,
        email: email,
        password: password,
        preferredLanguage: _languageCode,
      );

      final result = await AuthService.loginWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.user.role != 'RESEARCHER') {
        _message('ORCA returned an invalid account role.');
        return;
      }

      await SessionService.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(role: UserRole.researcher),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('Could not create the Researcher account.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                  'Create Researcher\nAccount',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Public registration is available only for '
                  'Marine Researcher accounts.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  enabled: !isLoading,
                  decoration: _field(
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _field(
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: obscurePassword,
                  decoration:
                      _field(
                        label: 'Create Password',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: obscureConfirmPassword,
                  decoration:
                      _field(
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
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
                        Icons.translate_rounded,
                        color: AppTheme.indigo,
                        background: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Preferred language: ${widget.selectedLanguage}\n'
                          'ORCA will save this preference with the account.',
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
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account & Enter ORCA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _field({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }
}
