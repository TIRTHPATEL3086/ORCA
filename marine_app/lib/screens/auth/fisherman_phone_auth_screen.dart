import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import 'fisherman_otp_screen.dart';

class FishermanPhoneAuthScreen extends StatefulWidget {
  final String selectedLanguage;

  const FishermanPhoneAuthScreen({super.key, required this.selectedLanguage});

  @override
  State<FishermanPhoneAuthScreen> createState() =>
      _FishermanPhoneAuthScreenState();
}

class _FishermanPhoneAuthScreenState extends State<FishermanPhoneAuthScreen> {
  final phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.length < 10) {
      _message('Enter a valid mobile number.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.requestFishermanOtp(phone);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FishermanOtpScreen(
            phoneNumber: phone,
            selectedLanguage: widget.selectedLanguage,
            initialDevOtp: result.devOtp,
            expiresInSeconds: result.expiresInSeconds,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message(
          'Could not connect to ORCA. Check the backend and ADB reverse.',
        );
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
                    const Expanded(child: PillProgress(value: 0.33)),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      OrcaMascot(size: 120, mood: MascotMood.happy, halo: true),
                      Positioned(
                        right: -6,
                        bottom: 6,
                        child: SoftIcon(
                          Icons.phishing_rounded,
                          color: AppTheme.coralDeep,
                          background: AppTheme.coralSoft,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Fisherman Access',
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
                  'Use your mobile number to securely enter ORCA. '
                  'No email or complex password is required.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: phoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '98765 43210',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 16, right: 10),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '+91',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                        Icons.language_rounded,
                        color: AppTheme.indigo,
                        background: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selected language: ${widget.selectedLanguage}\n'
                          'ORCA will keep this preference during onboarding.',
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
                  onPressed: isLoading ? null : _sendOtp,
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
