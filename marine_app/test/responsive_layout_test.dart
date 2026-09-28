// Renders every ORCA screen on a range of phone, tablet and landscape sizes
// (plus large accessibility text) and fails on any layout overflow.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marine_app/core/responsive.dart';
import 'package:marine_app/core/theme/app_theme.dart';
import 'package:marine_app/models/gis_models.dart';
import 'package:marine_app/models/user_role.dart';
import 'package:marine_app/screens/auth/admin_login_screen.dart';
import 'package:marine_app/screens/auth/authority_login_screen.dart';
import 'package:marine_app/screens/auth/fisherman_otp_screen.dart';
import 'package:marine_app/screens/auth/fisherman_phone_auth_screen.dart';
import 'package:marine_app/screens/auth/fisherman_registration_screen.dart';
import 'package:marine_app/screens/auth/register_screen.dart';
import 'package:marine_app/screens/auth/researcher_login_screen.dart';
import 'package:marine_app/screens/dashboard/dashboard_screen.dart';
import 'package:marine_app/screens/gis/boundary_guardian_screen.dart';
import 'package:marine_app/screens/gis/mission_tracking_screen.dart';
import 'package:marine_app/screens/gis/plan_trip_screen.dart';
import 'package:marine_app/screens/landing_screen.dart';
import 'package:marine_app/screens/language_screen.dart';
import 'package:marine_app/screens/marine/sea_conditions_screen.dart';
import 'package:marine_app/screens/onboarding_guide_screen.dart';
import 'package:marine_app/screens/orca/ask_orca_screen.dart';
import 'package:marine_app/screens/profile/fisherman_profile_screen.dart';
import 'package:marine_app/screens/role_selection_screen.dart';
import 'package:marine_app/screens/splash_screen.dart';
import 'package:marine_app/screens/vessel/vessel_form_screen.dart';
import 'package:marine_app/screens/vessel/vessel_list_screen.dart';

class _Device {
  final String name;
  final Size size;
  final double textScale;

  const _Device(this.name, this.size, [this.textScale = 1.0]);
}

const _devices = [
  _Device('iPhone SE (1st gen) 320x568', Size(320, 568)),
  _Device('Small Android 360x640', Size(360, 640)),
  _Device('iPhone SE 375x667', Size(375, 667)),
  _Device('iPhone 14 390x844', Size(390, 844)),
  _Device('Pixel 7 412x915', Size(412, 915)),
  _Device('iPhone Pro Max 430x932', Size(430, 932)),
  _Device('Foldable 600x900', Size(600, 900)),
  _Device('Tablet 800x1280', Size(800, 1280)),
  _Device('Phone landscape 740x360', Size(740, 360)),
  _Device('Large text 1.3x 360x640', Size(360, 640), 1.3),
  _Device('Huge text 2.0x 390x844', Size(390, 844), 2.0),
];

final _route = RouteAlternativeData(
  routeId: 'fastest',
  title: 'Fastest route',
  distanceNm: 12.4,
  etaMinutes: 95,
  exposureScore: 0.4,
  maxWaveHeightM: 1.2,
  maxWindSpeedMs: 6.5,
  maxWindGustMs: 9.1,
  averageCurrentMs: 0.3,
  routeStatus: 'caution',
  routeMessage: 'Moderate exposure on the outer leg.',
  rationale: const ['Shortest distance', 'Moderate wind exposure'],
  waypoints: [
    for (var i = 0; i < 3; i++)
      RouteWaypointData(
        latitude: 21.0 + i * 0.05,
        longitude: 72.0 + i * 0.05,
        sequence: i,
        condition: RouteConditionData.fromJson(const {}),
      ),
  ],
);

final Map<String, Widget Function()> _screens = {
  'Splash': () => const SplashScreen(),
  'Landing': () => const LandingScreen(),
  'Language': () => const LanguageScreen(),
  'Role selection': () => const RoleSelectionScreen(selectedLanguage: 'English'),
  'Onboarding guide': () => const OnboardingGuideScreen(),
  'Admin login': () => const AdminLoginScreen(),
  'Authority login': () => const AuthorityLoginScreen(),
  'Researcher login': () =>
      const ResearcherLoginScreen(selectedLanguage: 'English'),
  'Register': () => const RegisterScreen(selectedLanguage: 'English'),
  'Fisherman phone': () =>
      const FishermanPhoneAuthScreen(selectedLanguage: 'English'),
  'Fisherman OTP': () => const FishermanOtpScreen(
        phoneNumber: '+919876543210',
        selectedLanguage: 'English',
        initialDevOtp: '123456',
        expiresInSeconds: 300,
      ),
  'Fisherman registration': () => const FishermanRegistrationScreen(
        phoneNumber: '+919876543210',
        selectedLanguage: 'English',
        onboardingToken: 'token',
      ),
  for (final role in UserRole.values)
    'Dashboard (${role.name})': () => DashboardScreen(role: role),
  'Profile': () => const FishermanProfileScreen(),
  'Vessel list': () => const VesselListScreen(),
  'Vessel form': () => const VesselFormScreen(),
  'Plan trip': () => const PlanTripScreen(),
  'Boundary guardian': () => const BoundaryGuardianScreen(),
  'Sea conditions': () => const SeaConditionsScreen(),
  'Ask ORCA': () => const AskOrcaScreen(),
  'Mission tracking': () =>
      MissionTrackingScreen(route: _route, cruisingSpeedKnots: 8),
};

void _mockPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'flutter_tts',
    'plugins.it_nomads.com/flutter_secure_storage',
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geolocator_android',
    'flutter.baseflow.com/geolocator_apple',
    'plugin.csdcorp.com/speech_to_text',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return false;
        case 'checkPermission':
          return 0;
        case 'initialize':
        case 'has_speech_permission':
          return false;
        default:
          return null;
      }
    });
  }
}

bool _isLayoutError(FlutterErrorDetails d) {
  final text = d.exceptionAsString();
  return text.contains('overflowed') ||
      text.contains('was not laid out') ||
      text.contains('unbounded') ||
      text.contains('infinite size') ||
      text.contains('BoxConstraints forces an infinite');
}

const _indicFallback = 'IndicTest';

/// Localised screens, checked in every supported language.
final Map<String, Widget Function(String language)> _localisedScreens = {
  'Role selection': (l) => RoleSelectionScreen(selectedLanguage: l),
  'Researcher login': (l) => ResearcherLoginScreen(selectedLanguage: l),
  'Register': (l) => RegisterScreen(selectedLanguage: l),
  'Fisherman phone': (l) => FishermanPhoneAuthScreen(selectedLanguage: l),
  'Fisherman OTP': (l) => FishermanOtpScreen(
        phoneNumber: '+919876543210',
        selectedLanguage: l,
        initialDevOtp: '123456',
        expiresInSeconds: 300,
      ),
  'Fisherman registration': (l) => FishermanRegistrationScreen(
        phoneNumber: '+919876543210',
        selectedLanguage: l,
        onboardingToken: 'token',
      ),
  'Onboarding guide': (l) => OnboardingGuideScreen(initialLanguageCode: l),
};

Future<void> _expectNoOverflow(
  WidgetTester tester,
  _Device device,
  String label,
  Widget screen,
) async {
  tester.view.physicalSize = device.size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final layoutErrors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isLayoutError(details)) {
      layoutErrors.add(
        details
            .toString()
            .split('\n')
            .where(
              (l) =>
                  l.contains('overflowed') ||
                  l.contains('file:///') ||
                  l.contains('The relevant error-causing widget'),
            )
            .take(4)
            .join('\n'),
      );
    }
  };

  final base = AppTheme.lightTheme;
  try {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          textTheme: base.textTheme.apply(
            fontFamilyFallback: const [_indicFallback],
          ),
        ),
        builder: Responsive.appBuilder,
        home: DefaultTextStyle.merge(
          style: const TextStyle(fontFamilyFallback: [_indicFallback]),
          child: screen,
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Scroll through the main vertical list so content below the fold is
    // laid out and checked too.
    final scrollables = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (scrollables.evaluate().isNotEmpty) {
      final main = scrollables.first;
      for (var i = 0; i < 25; i++) {
        await tester.drag(main, const Offset(0, -400), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
  } finally {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 40));
    FlutterError.onError = previous;
  }

  // Swallow non-layout exceptions (network, plugins) raised in tests.
  tester.takeException();

  expect(
    layoutErrors,
    isEmpty,
    reason: '$label on ${device.name}:\n${layoutErrors.join('\n---\n')}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use the real app font so text is measured as it is on a device, plus
  // an Indic-script font (Windows' Nirmala UI) for the regional languages.
  setUpAll(() async {
    final loader = FontLoader(AppTheme.fontFamily);
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await loader.load();

    final nirmala = File(r'C:\Windows\Fonts\Nirmala.ttc');
    if (nirmala.existsSync()) {
      final bytes = nirmala.readAsBytesSync();
      await (FontLoader(_indicFallback)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockPlugins();
  });

  for (final device in _devices) {
    group(device.name, () {
      for (final entry in _screens.entries) {
        testWidgets(entry.key, (tester) async {
          await _expectNoOverflow(tester, device, entry.key, entry.value());
        });
      }
    });
  }

  const languages = ['hi', 'gu', 'mr', 'te', 'ta', 'kn', 'ml', 'bn', 'or'];
  const smallDevices = [
    _Device('320x568', Size(320, 568)),
    _Device('360x640 at 1.3x text', Size(360, 640), 1.3),
  ];
  for (final device in smallDevices) {
    for (final lang in languages) {
      group('[$lang] ${device.name}', () {
        for (final entry in _localisedScreens.entries) {
          testWidgets(entry.key, (tester) async {
            await _expectNoOverflow(
              tester,
              device,
              '${entry.key} ($lang)',
              entry.value(lang),
            );
          });
        }
      });
    }
  }
}
