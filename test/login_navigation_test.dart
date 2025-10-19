import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/login_page.dart';
import 'package:new_project/widgets/app_drawer.dart';

void main() {
  group('Login Navigation Tests', () {
    testWidgets('Tapping تسجيل دخول button in drawer navigates to /login', (
      WidgetTester tester,
    ) async {
      // Create a minimal app with drawer
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test App')),
              drawer: AppDrawer(toggleTheme: (isDark) {}),
              body: const Center(child: Text('Home')),
            ),
            routes: {
              '/login': (context) => LoginPage(toggleTheme: (isDark) {}),
            },
          ),
        ),
      );

      // Open the drawer
      await tester.tap(find.byType(AppBar));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find and tap the login button
      final loginButton = find.text('تسجيل دخول');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify we navigated to login page by checking for tabs
      expect(find.text('دخول المستخدمين'), findsOneWidget);
      expect(find.text('دخول الشيوخ'), findsOneWidget);
    });

    testWidgets('LoginPage renders two tabs with correct Arabic labels', (
      WidgetTester tester,
    ) async {
      // Create the login page directly
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(home: LoginPage(toggleTheme: (isDark) {})),
        ),
      );

      // Verify both tabs exist
      expect(find.text('دخول المستخدمين'), findsOneWidget);
      expect(find.text('دخول الشيوخ'), findsOneWidget);

      // Verify we start on the user login tab (default)
      expect(find.text('البريد الإلكتروني'), findsOneWidget);

      // Switch to sheikh tab
      await tester.tap(find.text('دخول الشيوخ'));
      await tester.pumpAndSettle();

      // Verify sheikh login form is shown
      expect(find.text('المعرف الفريد'), findsOneWidget);

      // Verify both tabs have login button with correct text
      expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    });

    testWidgets('User tab shows email field and register link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(
            home: LoginPage(toggleTheme: (isDark) {}),
            routes: {
              '/register': (context) =>
                  const Scaffold(body: Center(child: Text('Register Page'))),
            },
          ),
        ),
      );

      // Verify user tab elements
      expect(find.text('دخول المستخدمين'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    });

    testWidgets('Sheikh tab shows uniqueId field and NO register link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(home: LoginPage(toggleTheme: (isDark) {})),
        ),
      );

      // Switch to sheikh tab
      await tester.tap(find.text('دخول الشيوخ'));
      await tester.pumpAndSettle();

      // Verify sheikh tab elements
      expect(find.text('المعرف الفريد'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);

      // Verify NO register link in sheikh tab
      expect(find.text('إنشاء حساب جديد'), findsNothing);
    });

    testWidgets('Route /login resolves to LoginPage with two tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(
            initialRoute: '/login',
            routes: {
              '/login': (context) => LoginPage(toggleTheme: (isDark) {}),
            },
          ),
        ),
      );

      // Verify we're on login page with two tabs
      expect(find.text('دخول المستخدمين'), findsOneWidget);
      expect(find.text('دخول الشيوخ'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    });
  });
}
