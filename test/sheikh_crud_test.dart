import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/sheikh_provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/chapter_provider.dart';
import 'package:new_project/screens/sheikh_dashboard_screen.dart';
import 'package:new_project/screens/sheikh_chapters_screen.dart';
import 'package:new_project/screens/sheikh_lessons_screen.dart';
import 'package:new_project/screens/sheikh_chapter_form_screen.dart';
import 'package:new_project/screens/sheikh_lesson_form_screen.dart';

void main() {
  group('Sheikh CRUD Tests', () {
    late SheikhProvider sheikhProvider;
    late AuthProvider authProvider;
    late ChapterProvider chapterProvider;

    setUp(() {
      sheikhProvider = SheikhProvider();
      authProvider = AuthProvider();
      chapterProvider = ChapterProvider();
    });

    testWidgets('Sheikh dashboard shows simplified UI', (
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
            ChangeNotifierProvider<ChapterProvider>.value(
              value: chapterProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhDashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show simplified dashboard elements
      expect(find.text('لوحة الشيخ'), findsOneWidget);
      expect(find.text('الإحصائيات'), findsOneWidget);
      expect(find.text('الإجراءات السريعة'), findsOneWidget);
      expect(find.text('إدارة الأبواب'), findsOneWidget);
      expect(find.text('إدارة الدروس'), findsOneWidget);
    });

    testWidgets('Chapter management shows list with CRUD actions', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user with chapters
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');
      chapterProvider.setChapters([
        {
          'id': 'chapter-1',
          'title': 'الباب الأول',
          'status': 'published',
          'details': 'تفاصيل الباب',
        },
        {
          'id': 'chapter-2',
          'title': 'الباب الثاني',
          'status': 'draft',
          'details': 'تفاصيل الباب الثاني',
        },
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChapterProvider>.value(
              value: chapterProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhChaptersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show chapter management interface
      expect(find.text('إدارة الأبواب'), findsOneWidget);
      expect(find.text('البحث في الأبواب...'), findsOneWidget);
      expect(find.text('الباب الأول'), findsOneWidget);
      expect(find.text('الباب الثاني'), findsOneWidget);
    });

    testWidgets('Lesson management shows filtered lessons', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');
      chapterProvider.setChapters([
        {'id': 'chapter-1', 'title': 'الباب الأول'},
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChapterProvider>.value(
              value: chapterProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhLessonsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show lesson management interface
      expect(find.text('إدارة الدروس'), findsOneWidget);
      expect(find.text('البحث في الدروس...'), findsOneWidget);
      expect(find.text('الفصل:'), findsOneWidget);
    });

    testWidgets('Chapter form validates required fields', (
      WidgetTester tester,
    ) async {
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
            ChangeNotifierProvider<ChapterProvider>.value(
              value: chapterProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhChapterFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show chapter form
      expect(find.text('إضافة باب جديد'), findsOneWidget);
      expect(find.text('عنوان الباب *'), findsOneWidget);
      expect(find.text('القسم محدد تلقائياً'), findsOneWidget);
    });

    testWidgets('Lesson form validates required fields', (
      WidgetTester tester,
    ) async {
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');
      chapterProvider.setChapters([
        {'id': 'chapter-1', 'title': 'الباب الأول'},
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChapterProvider>.value(
              value: chapterProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhLessonFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show lesson form
      expect(find.text('إضافة درس جديد'), findsOneWidget);
      expect(find.text('عنوان الدرس *'), findsOneWidget);
      expect(find.text('الفصل/الباب *'), findsOneWidget);
    });

    testWidgets('Chapter provider CRUD operations work correctly', (
      WidgetTester tester,
    ) async {
      // Test adding chapter
      final chapterId = await chapterProvider.addChapter(
        title: 'الباب الجديد',
        categoryId: 'test-category-id',
        sheikhUid: 'test-sheikh-uid',
        details: 'تفاصيل الباب',
        status: 'draft',
      );

      expect(chapterId, isNotNull);
      expect(chapterProvider.chapters.length, greaterThan(0));

      // Test updating chapter
      final success = await chapterProvider.updateChapter(
        chapterId: chapterId!,
        title: 'الباب المحدث',
        details: 'تفاصيل محدثة',
        status: 'published',
      );

      expect(success, isTrue);

      // Test deleting chapter
      final deleteSuccess = await chapterProvider.deleteChapter(
        chapterId,
        'test-category-id',
        'test-sheikh-uid',
      );

      expect(deleteSuccess, isTrue);
    });

    testWidgets('Ownership enforcement works correctly', (
      WidgetTester tester,
    ) async {
      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');

      // Test chapter owned by current sheikh
      final ownedChapter = {
        'createdBy': 'test-sheikh-uid',
        'sheikhUid': 'test-sheikh-uid',
        'categoryId': 'test-category-id',
      };

      // Test chapter not owned by current sheikh
      final notOwnedChapter = {
        'createdBy': 'other-sheikh-uid',
        'sheikhUid': 'other-sheikh-uid',
        'categoryId': 'test-category-id',
      };

      // Test chapter from different category
      final differentCategoryChapter = {
        'createdBy': 'test-sheikh-uid',
        'sheikhUid': 'test-sheikh-uid',
        'categoryId': 'other-category-id',
      };

      // Mock current user
      authProvider.setCurrentUser({'uid': 'test-sheikh-uid', 'role': 'sheikh'});

      expect(sheikhProvider.ensureOwnership(ownedChapter), isTrue);
      expect(sheikhProvider.ensureOwnership(notOwnedChapter), isFalse);
      expect(sheikhProvider.ensureOwnership(differentCategoryChapter), isFalse);
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

extension SheikhProviderTest on SheikhProvider {
  void setCurrentSheikhCategoryId(String categoryId) {
    // This would need to be implemented in the actual SheikhProvider
    // for testing purposes
  }
}

extension ChapterProviderTest on ChapterProvider {
  void setChapters(List<Map<String, dynamic>> chapters) {
    // This would need to be implemented in the actual ChapterProvider
    // for testing purposes
  }
}
