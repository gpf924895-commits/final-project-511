import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/utils/auth_guard.dart';
import 'package:new_project/screens/login_page.dart';

void main() {
  group('Auth Guard Tests', () {
    testWidgets('requireAuth returns true for authenticated user', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();
      // Simulate logged in state
      authProvider.loginUser(email: 'test@test.com', password: 'test123');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final result = await AuthGuard.requireAuth(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Result: $result')));
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Since user is logged in, no dialog should appear
      expect(find.text('تسجيل الدخول مطلوب'), findsNothing);
    });

    testWidgets('requireAuth shows dialog for guest user', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(context);
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
            routes: {
              '/login': (context) => LoginPage(toggleTheme: (isDark) {}),
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);
      expect(
        find.text('يجب تسجيل الدخول أولاً لإتمام هذه العملية.'),
        findsOneWidget,
      );
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('Tapping message body navigates to login', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(context);
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
            routes: {
              '/login': (context) =>
                  const Scaffold(body: Center(child: Text('Login Page'))),
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Tap on the message body
      await tester.tap(find.text('يجب تسجيل الدخول أولاً لإتمام هذه العملية.'));
      await tester.pumpAndSettle();

      // Should navigate to login page
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Tapping primary button navigates to login', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(context);
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
            routes: {
              '/login': (context) =>
                  const Scaffold(body: Center(child: Text('Login Page'))),
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Find the ElevatedButton with text 'تسجيل الدخول'
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should navigate to login page
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Tapping cancel button dismisses dialog', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(context);
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
            routes: {
              '/login': (context) =>
                  const Scaffold(body: Center(child: Text('Login Page'))),
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('تسجيل الدخول مطلوب'), findsNothing);
      // Should still be on home screen
      expect(find.text('Check Auth'), findsOneWidget);
    });

    testWidgets('Tapping outside dialog dismisses it', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(context);
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);

      // Tap outside dialog (on barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('تسجيل الدخول مطلوب'), findsNothing);
    });

    testWidgets('onLoginSuccess callback fires after successful login', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();
      bool callbackFired = false;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AuthGuard.requireAuth(
                      context,
                      onLoginSuccess: () {
                        callbackFired = true;
                      },
                    );
                  },
                  child: const Text('Check Auth'),
                );
              },
            ),
            routes: {
              '/login': (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Simulate successful login
                      authProvider.loginUser(
                        email: 'test@test.com',
                        password: 'test123',
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Mock Login'),
                  ),
                ),
              ),
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      // Navigate to login and mock login
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mock Login'));
      await tester.pumpAndSettle();

      // Callback should have fired
      expect(callbackFired, true);
    });
  });
}
