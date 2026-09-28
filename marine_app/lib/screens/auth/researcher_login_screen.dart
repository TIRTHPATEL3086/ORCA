import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class ResearcherLoginScreen extends StatefulWidget {
  final String selectedLanguage;

  const ResearcherLoginScreen({super.key, required this.selectedLanguage});

  @override
  State<ResearcherLoginScreen> createState() => _ResearcherLoginScreenState();
}

class _ResearcherLoginScreenState extends State<ResearcherLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message('Enter your email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.loginWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.user.role != 'RESEARCHER') {
        _message(
          'This account is not authorized for the Researcher workspace.',
        );
        return;
      }

      await SessionService.saveSession(
        accessToken: result.accessToken,
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
        _message('Could not connect to ORCA. Check the backend connection.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RegisterScreen(selectedLanguage: widget.selectedLanguage),
      ),
    );
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
                const SizedBox(height: 18),
                const Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      OrcaMascot(
                        size: 120,
                        mood: MascotMood.sparkle,
                        halo: true,
                      ),
                      Positioned(
                        right: -6,
                        bottom: 6,
                        child: SoftIcon(
                          Icons.science_rounded,
                          color: AppTheme.ink,
                          background: AppTheme.lime,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Marine Researcher',
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
                  'Sign in to the ORCA research workspace for '
                  'marine datasets, spatial-temporal analysis, '
                  'anomalies, evidence and reporting.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                  decoration:
                      _field(
                        label: 'Password',
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _signIn,
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In to Research Workspace'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _openRegistration,
                    child: const Text('New researcher? Create an account'),
                  ),
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
