import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/utils/auth_guard.dart';
import 'package:new_project/screens/home_page.dart';
import 'package:new_project/screens/login_page.dart';

void main() {
  group('Guest Mode Tests', () {
    testWidgets('App launches in guest mode', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: HomePage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      // Should be in guest mode by default
      expect(authProvider.isGuest, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoggedIn, false);

      // Should see guest mode indicator
      expect(find.text('وضع الضيف'), findsOneWidget);
    });

    testWidgets('Guest can browse content', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: HomePage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should see home page content
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('محاضرات'), findsOneWidget);
    });

    testWidgets('Restricted action triggers login dialog in guest mode', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await AuthGuard.requireAuth(context);
                    },
                    child: const Text('Restricted Action'),
                  ),
                );
              },
            ),
            routes: {
              '/login': (context) => LoginPage(toggleTheme: (isDark) {}),
            },
          ),
        ),
      );

      // Verify guest mode
      expect(authProvider.isGuest, true);

      // Tap restricted action
      await tester.tap(find.text('Restricted Action'));
      await tester.pumpAndSettle();

      // Should show login prompt dialog
      expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);
      expect(
        find.text('يجب تسجيل الدخول أولاً لإتمام هذه العملية.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping login button navigates to login page', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await AuthGuard.requireAuth(context);
                    },
                    child: const Text('Restricted Action'),
                  ),
                );
              },
            ),
            routes: {
              '/login': (context) => const Scaffold(
                body: Center(child: Text('Login Page')),
              ),
            },
          ),
        ),
      );

      // Tap restricted action
      await tester.tap(find.text('Restricted Action'));
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should navigate to login page
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('After login, pending action resumes', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();
      bool actionExecuted = false;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      final authenticated = await AuthGuard.requireAuth(
                        context,
                        onLoginSuccess: () {
                          actionExecuted = true;
                        },
                      );
                      if (authenticated) {
                        actionExecuted = true;
                      }
                    },
                    child: const Text('Restricted Action'),
                  ),
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

      // Tap restricted action
      await tester.tap(find.text('Restricted Action'));
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      // Mock login
      await tester.tap(find.text('Mock Login'));
      await tester.pumpAndSettle();

      // Action should have been executed
      expect(actionExecuted, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isGuest, false);
    });

    testWidgets('Logout returns to guest mode', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      // Simulate logged in state
      authProvider.loginUser(email: 'test@test.com', password: 'test123');
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isGuest, false);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await authProvider.signOut();
                },
                child: const Text('Logout'),
              ),
            ),
          ),
        ),
      );

      // Logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Should return to guest mode
      expect(authProvider.isGuest, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
    });

    testWidgets('Guest mode shows correct UI elements', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: HomePage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show guest indicator in AppBar
      expect(find.text('وضع الضيف'), findsOneWidget);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should show guest mode in drawer
      expect(find.text('وضع الضيف'), findsAtLeastNWidgets(1));
      expect(find.text('تصفح بدون حساب'), findsOneWidget);
      expect(find.text('تسجيل دخول'), findsOneWidget);
    });

    testWidgets('Authenticated user does not see guest indicator', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      // Simulate logged in state
      authProvider.loginUser(email: 'test@test.com', password: 'test123');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: HomePage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT show guest indicator
      expect(find.text('وضع الضيف'), findsNothing);
    });

    test('AuthProvider initializes in guest mode', () {
      final authProvider = AuthProvider();

      expect(authProvider.isGuest, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
    });

    test('enterGuestMode sets correct state', () {
      final authProvider = AuthProvider();

      // Simulate logged in state
      authProvider.loginUser(email: 'test@test.com', password: 'test123');
      expect(authProvider.isGuest, false);
      expect(authProvider.isAuthenticated, true);

      // Enter guest mode
      authProvider.enterGuestMode();

      expect(authProvider.isGuest, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.errorMessage, null);
    });

    test('Successful login exits guest mode', () {
      final authProvider = AuthProvider();

      expect(authProvider.isGuest, true);

      // Simulate successful login
      authProvider.loginUser(email: 'test@test.com', password: 'test123');

      expect(authProvider.isGuest, false);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isLoggedIn, true);
    });
  });
}

