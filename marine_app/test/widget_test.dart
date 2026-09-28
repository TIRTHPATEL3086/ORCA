import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_app/core/responsive.dart';
import 'package:marine_app/core/theme/app_theme.dart';
import 'package:marine_app/screens/splash_screen.dart';

void main() {
  testWidgets('ORCA splash screen opens and navigates to the landing page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: Responsive.appBuilder,
        home: const SplashScreen(),
      ),
    );

    expect(find.text('ORCA'), findsOneWidget);
    expect(find.text('MARINE INTELLIGENCE'), findsOneWidget);
    expect(find.text('Intelligence that travels with you.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Get started'), findsWidgets);
    expect(find.text('How ORCA works'), findsOneWidget);
  });
}
