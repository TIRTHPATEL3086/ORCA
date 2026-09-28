import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import 'fisherman_registration_screen.dart';

class FishermanOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String selectedLanguage;
  final String? initialDevOtp;
  final int expiresInSeconds;

  const FishermanOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.selectedLanguage,
    required this.initialDevOtp,
    required this.expiresInSeconds,
  });

  @override
  State<FishermanOtpScreen> createState() => _FishermanOtpScreenState();
}

class _FishermanOtpScreenState extends State<FishermanOtpScreen> {
  final otpController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;
  late int secondsRemaining;
  Timer? timer;
  String? devOtp;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.expiresInSeconds;
    devOtp = widget.initialDevOtp;
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (secondsRemaining <= 1) {
        timer.cancel();
        setState(() => secondsRemaining = 0);
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _message('Enter the 6-digit OTP.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.verifyFishermanOtp(
        phoneNumber: widget.phoneNumber,
        otp: otp,
      );

      if (!mounted) return;

      if (result.isNewUser) {
        final token = result.onboardingToken;

        if (token == null || token.isEmpty) {
          _message('ORCA did not return a valid onboarding token.');
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FishermanRegistrationScreen(
              phoneNumber: widget.phoneNumber,
              selectedLanguage: widget.selectedLanguage,
              onboardingToken: token,
            ),
          ),
        );
        return;
      }

      final accessToken = result.accessToken;
      final user = result.user;

      if (accessToken == null || user == null) {
        _message('ORCA returned an incomplete login response.');
        return;
      }

      if (user.role != 'FISHERMAN') {
        _message('This account is not authorized for the Fisherman workspace.');
        return;
      }

      await SessionService.saveSession(accessToken: accessToken, user: user);

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
        _message('Could not verify the OTP. Check the backend connection.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (isResending) return;

    setState(() => isResending = true);

    try {
      final result = await AuthService.requestFishermanOtp(widget.phoneNumber);

      if (!mounted) return;

      setState(() {
        devOtp = result.devOtp;
        secondsRemaining = result.expiresInSeconds;
        otpController.clear();
      });

      _startTimer();
      _message('A new OTP was generated.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('Could not request a new OTP.');
      }
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _timerText() {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
                    const Expanded(child: PillProgress(value: 0.66)),
                    const SizedBox(width: 12),
                  ],
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
                          Icons.sms_outlined,
                          color: AppTheme.indigo,
                          background: AppTheme.lavenderSoft,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Verify your number',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code for '
                  '${widget.phoneNumber}.',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (devOtp != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.butter,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bug_report_outlined,
                          color: AppTheme.ink,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Development OTP: $devOtp',
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: otpController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 14,
                  ),
                  onSubmitted: (_) => _verify(),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: AppTheme.line,
                      letterSpacing: 14,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _verify,
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text('Verify & Continue'),
                ),
                const SizedBox(height: 14),
                Center(
                  child: secondsRemaining > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            'Code expires in ${_timerText()}',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: isResending ? null : _resendOtp,
                          child: Text(
                            isResending ? 'Requesting...' : 'Request a new OTP',
                          ),
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
