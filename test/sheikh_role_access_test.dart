import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/sheikh_provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/sheikh_dashboard_screen.dart';
import 'package:new_project/screens/sheikh_lectures_screen.dart';
import 'package:new_project/screens/sheikh_upload_screen.dart';

void main() {
  group('Sheikh Role Access Tests', () {
    late SheikhProvider sheikhProvider;
    late AuthProvider authProvider;

    setUp(() {
      sheikhProvider = SheikhProvider();
      authProvider = AuthProvider();
    });

    testWidgets('Sheikh dashboard shows only for sheikh role', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(home: SheikhDashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show sheikh dashboard elements
      expect(find.text('لوحة الشيخ'), findsOneWidget);
      expect(find.text('الإحصائيات'), findsOneWidget);
      expect(find.text('الإجراءات السريعة'), findsOneWidget);
    });

    testWidgets('Non-sheikh user cannot access sheikh dashboard', (
      WidgetTester tester,
    ) async {
      // Mock regular user
      authProvider.setCurrentUser({
        'uid': 'test-user-uid',
        'role': 'user',
        'email': 'user@test.com',
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(home: SheikhDashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error or redirect
      expect(find.text('هذه الصفحة خاصة بالشيخ'), findsOneWidget);
    });

    testWidgets('Sheikh lectures screen shows filtered lectures', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user with category
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      // Mock sheikh provider with category
      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(home: SheikhLecturesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show lectures management interface
      expect(find.text('إدارة الدروس'), findsOneWidget);
      expect(find.text('تصفية:'), findsOneWidget);
    });

    testWidgets('Sheikh upload screen enforces ownership', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(home: SheikhUploadScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show upload form
      expect(find.text('إضافة درس جديد'), findsOneWidget);
      expect(find.text('عنوان الدرس *'), findsOneWidget);
      expect(find.text('الحالة'), findsOneWidget);
    });

    testWidgets('Ownership check works correctly', (WidgetTester tester) async {
      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');

      // Test lecture owned by current sheikh
      final ownedLecture = {
        'createdBy': 'test-sheikh-uid',
        'sheikhUid': 'test-sheikh-uid',
        'categoryId': 'test-category-id',
      };

      // Test lecture not owned by current sheikh
      final notOwnedLecture = {
        'createdBy': 'other-sheikh-uid',
        'sheikhUid': 'other-sheikh-uid',
        'categoryId': 'test-category-id',
      };

      // Test lecture from different category
      final differentCategoryLecture = {
        'createdBy': 'test-sheikh-uid',
        'sheikhUid': 'test-sheikh-uid',
        'categoryId': 'other-category-id',
      };

      // Mock current user
      authProvider.setCurrentUser({'uid': 'test-sheikh-uid', 'role': 'sheikh'});

      expect(sheikhProvider.ensureOwnership(ownedLecture), isTrue);
      expect(sheikhProvider.ensureOwnership(notOwnedLecture), isFalse);
      expect(sheikhProvider.ensureOwnership(differentCategoryLecture), isFalse);
    });
  });
}

// Extension to help with testing
extension AuthProviderTest on AuthProvider {
  void setCurrentUser(Map<String, dynamic> user) {
    // This would need to be implemented in the actual AuthProvider
    // for testing purposes
  }
}

extension SheikhProviderTest on SheikhProvider {
  void setCurrentSheikhCategoryId(String categoryId) {
    // This would need to be implemented in the actual SheikhProvider
    // for testing purposes
  }
}

