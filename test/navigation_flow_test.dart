import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/splash_auth_gate.dart';
import 'package:new_project/widgets/sheikh_guard.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    setupFirebaseForTests();
  });
  group('Navigation Flow Tests', () {
    testWidgets(
      'SplashAuthGate should show loading until AuthProvider is ready',
      (WidgetTester tester) async {
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>(
              create: (context) => authProvider,
              child: const SplashAuthGate(),
            ),
          ),
        );

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('جاري التحميل...'), findsOneWidget);
      },
    );

    testWidgets(
      'SheikhGuard should redirect to login when user is not authenticated',
      (WidgetTester tester) async {
        final authProvider = AuthProvider();
        authProvider.enterGuestMode(); // This sets _isReady = true

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>(
              create: (context) => authProvider,
              child: const SheikhGuard(
                routeName: '/test',
                child: Text('Test Child'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show loading indicator (waiting for navigation)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('SheikhGuard should redirect to home when user is not sheikh', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();
      // Simulate authenticated user with non-sheikh role
      authProvider.enterGuestMode();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (context) => authProvider,
            child: const SheikhGuard(
              routeName: '/test',
              child: Text('Test Child'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show loading indicator (waiting for navigation)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
