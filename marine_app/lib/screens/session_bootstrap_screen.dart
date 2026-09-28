import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/auth_models.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/session_validation_service.dart';
import '../widgets/orca_mascot.dart';
import '../widgets/talkie_ui.dart';
import 'dashboard/dashboard_screen.dart';
import 'splash_screen.dart';

class SessionBootstrapScreen extends StatefulWidget {
  const SessionBootstrapScreen({super.key});

  @override
  State<SessionBootstrapScreen> createState() => _SessionBootstrapScreenState();
}

class _SessionBootstrapScreenState extends State<SessionBootstrapScreen> {
  late final Future<Widget> _destination;

  @override
  void initState() {
    super.initState();
    _destination = _resolveDestination();
  }

  Future<Widget> _resolveDestination() async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      return const SplashScreen();
    }

    try {
      final user = await SessionValidationService.getCurrentUser();

      return _dashboardForRole(user);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await SessionService.clear();
        return const SplashScreen();
      }

      return _offlineFallback();
    } catch (_) {
      return _offlineFallback();
    }
  }

  Future<Widget> _offlineFallback() async {
    final cachedRole = await SessionService.getRole();

    // ORCA's offline-first mobile experience belongs to the
    // Fisherman role. Sensitive Authority/Admin/Researcher
    // workspaces still require live backend verification.
    if (cachedRole == 'FISHERMAN') {
      return const DashboardScreen(role: UserRole.fisherman);
    }

    return const SplashScreen();
  }

  Widget _dashboardForRole(AuthenticatedUser user) {
    switch (user.role) {
      case 'FISHERMAN':
        return const DashboardScreen(role: UserRole.fisherman);

      case 'RESEARCHER':
        return const DashboardScreen(role: UserRole.researcher);

      case 'AUTHORITY':
        return const DashboardScreen(role: UserRole.authority);

      case 'ADMIN':
        return const DashboardScreen(role: UserRole.admin);

      default:
        return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data ?? const SplashScreen();
        }

        return const Scaffold(
          body: GridBackground(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrcaMascot(size: 120, mood: MascotMood.calm, halo: true),
                  SizedBox(height: 18),
                  Text(
                    'ORCA',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppTheme.coral,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
