import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/widgets/sheikh_guard.dart';

void main() {
  group('SheikhGuard Tests', () {
    testWidgets(
      'SheikhGuard should show loading when AuthProvider is not ready',
      (WidgetTester tester) async {
        // Create a mock AuthProvider that is not ready
        final authProvider = AuthProvider();

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

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Test Child'), findsNothing);
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
