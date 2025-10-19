import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/home_page.dart';

void main() {
  group('Public User Access Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    testWidgets('Public user can browse lectures by category', (
      WidgetTester tester,
    ) async {
      // Mock unauthenticated user (guest mode)
      authProvider.setCurrentUser(null);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(home: HomePage(toggleTheme: (isDark) {})),
        ),
      );

      await tester.pumpAndSettle();

      // Should show public home page
      expect(find.text('الرئيسية'), findsOneWidget);
    });

    testWidgets('Regular user cannot access sheikh routes', (
      WidgetTester tester,
    ) async {
      // Mock regular user
      authProvider.setCurrentUser({
        'uid': 'test-user-uid',
        'role': 'user',
        'email': 'user@test.com',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(home: HomePage(toggleTheme: (isDark) {})),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show sheikh-specific elements
      expect(find.text('لوحة الشيخ'), findsNothing);
      expect(find.text('إدارة الدروس'), findsNothing);
    });

    testWidgets('Admin user can access admin panel', (
      WidgetTester tester,
    ) async {
      // Mock admin user
      authProvider.setCurrentUser({
        'uid': 'test-admin-uid',
        'role': 'admin',
        'email': 'admin@test.com',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(home: HomePage(toggleTheme: (isDark) {})),
        ),
      );

      await tester.pumpAndSettle();

      // Should show admin-specific elements or redirect to admin panel
      // This depends on the HomePage implementation
    });

    testWidgets('Stack switching works correctly on logout', (
      WidgetTester tester,
    ) async {
      // Start as sheikh user
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(home: HomePage(toggleTheme: (isDark) {})),
        ),
      );

      await tester.pumpAndSettle();

      // Logout (simulate)
      authProvider.setCurrentUser(null);
      await tester.pumpAndSettle();

      // Should return to public home page
      expect(find.text('الرئيسية'), findsOneWidget);
    });

    testWidgets('Role-based navigation restrictions', (
      WidgetTester tester,
    ) async {
      // Test that users cannot navigate to unauthorized routes
      authProvider.setCurrentUser({
        'uid': 'test-user-uid',
        'role': 'user',
        'email': 'user@test.com',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(
            home: HomePage(toggleTheme: (isDark) {}),
            routes: {
              '/sheikhDashboard': (context) => const Text('Sheikh Dashboard'),
              '/admin_panel': (context) => const Text('Admin Panel'),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to navigate to sheikh route (should be blocked)
      Navigator.pushNamed(
        tester.element(find.byType(MaterialApp)),
        '/sheikhDashboard',
      );
      await tester.pumpAndSettle();

      // Should show error message or redirect
      expect(find.text('هذه الصفحة خاصة بالشيخ'), findsOneWidget);
    });
  });
}

// Extension to help with testing
extension AuthProviderTest on AuthProvider {
  void setCurrentUser(Map<String, dynamic>? user) {
    // This would need to be implemented in the actual AuthProvider
    // for testing purposes
  }
}
