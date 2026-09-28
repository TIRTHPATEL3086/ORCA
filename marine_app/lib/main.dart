import 'package:flutter/material.dart';

import 'core/api_config.dart';
import 'core/responsive.dart';
import 'core/theme/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/profile/fisherman_profile_screen.dart';
import 'screens/session_bootstrap_screen.dart';
import 'services/api_client.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> _messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.warmUp();
  ApiClient.onSessionExpired = _returnToSignIn;
  runApp(const OrcaApp());
}

/// The session can no longer be renewed: send the user back to sign in.
void _returnToSignIn() {
  _navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LandingScreen()),
    (_) => false,
  );
  _messengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text(ApiClient.sessionEndedMessage)),
  );
}

class OrcaApp extends StatelessWidget {
  const OrcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORCA',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.lightTheme,
      builder: Responsive.appBuilder,
      home: const SessionBootstrapScreen(),
      routes: {'/fisherman/profile': (_) => const FishermanProfileScreen()},
    );
  }
}
