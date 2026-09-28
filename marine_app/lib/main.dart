import 'package:flutter/material.dart';

import 'core/responsive.dart';
import 'core/theme/app_theme.dart';
import 'screens/profile/fisherman_profile_screen.dart';
import 'screens/session_bootstrap_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrcaApp());
}

class OrcaApp extends StatelessWidget {
  const OrcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORCA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: Responsive.appBuilder,
      home: const SessionBootstrapScreen(),
      routes: {'/fisherman/profile': (_) => const FishermanProfileScreen()},
    );
  }
}
