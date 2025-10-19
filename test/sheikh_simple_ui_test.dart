import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/sheikh_provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/chapter_provider.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'package:new_project/screens/sheikh_simple_chapters_screen.dart';
import 'package:new_project/screens/sheikh_simple_lessons_screen.dart';
import 'package:new_project/screens/sheikh_simple_settings_screen.dart';

void main() {
  group('Sheikh Simple UI Tests', () {
    late SheikhProvider sheikhProvider;
    late AuthProvider authProvider;
    late ChapterProvider chapterProvider;
    late LectureProvider lectureProvider;

    setUp(() {
      sheikhProvider = SheikhProvider();
      authProvider = AuthProvider();
      chapterProvider = ChapterProvider();
      lectureProvider = LectureProvider();
    });

    testWidgets('Simple chapters screen shows minimal UI', (
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
        {
          'id': 'chapter-1',
          'title': 'الباب الأول',
          'status': 'published',
          'lessonsCount': 5,
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleChaptersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show minimal chapter management interface
      expect(find.text('البرامج/الأبواب'), findsOneWidget);
      expect(find.text('البحث في الأبواب...'), findsOneWidget);
      expect(find.text('الباب الأول'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // FAB
    });

    testWidgets('Simple lessons screen shows filtered lessons', (
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
      lectureProvider.setLectures([
        {
          'id': 'lesson-1',
          'title': 'الدرس الأول',
          'status': 'published',
          'chapterId': 'chapter-1',
          'updatedAt': null,
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleLessonsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show lesson management interface
      expect(find.text('الدروس'), findsOneWidget);
      expect(find.text('البحث في الدروس...'), findsOneWidget);
      expect(find.text('الدرس الأول'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // FAB
    });

    testWidgets('Simple settings screen shows profile info', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikh({
        'name': 'الشيخ أحمد',
        'email': 'sheikh@test.com',
        'sheikhId': '12345678',
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SheikhProvider>.value(value: sheikhProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(home: SheikhSimpleSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show settings interface
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('معلومات الشيخ'), findsOneWidget);
      expect(find.text('الشيخ أحمد'), findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsOneWidget);
    });

    testWidgets('Chapter swipe-to-delete shows confirmation', (
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
          'lessonsCount': 0,
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleChaptersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find the chapter card and swipe to delete
      final chapterCard = find.byType(Dismissible);
      expect(chapterCard, findsOneWidget);

      // Simulate swipe gesture
      await tester.drag(chapterCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(
        find.text('سيتم حذف هذا الباب وجميع الدروس التابعة له. هل أنت متأكد؟'),
        findsOneWidget,
      );
    });

    testWidgets('Lesson swipe-to-delete shows confirmation', (
      WidgetTester tester,
    ) async {
      // Mock sheikh user with lessons
      authProvider.setCurrentUser({
        'uid': 'test-sheikh-uid',
        'role': 'sheikh',
        'email': 'sheikh@test.com',
      });

      sheikhProvider.setCurrentSheikhCategoryId('test-category-id');
      chapterProvider.setChapters([
        {'id': 'chapter-1', 'title': 'الباب الأول'},
      ]);
      lectureProvider.setLectures([
        {
          'id': 'lesson-1',
          'title': 'الدرس الأول',
          'status': 'published',
          'chapterId': 'chapter-1',
          'updatedAt': null,
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleLessonsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find the lesson card and swipe to delete
      final lessonCard = find.byType(Dismissible);
      expect(lessonCard, findsOneWidget);

      // Simulate swipe gesture
      await tester.drag(lessonCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(find.text('سيتم حذف هذا الدرس. هل أنت متأكد؟'), findsOneWidget);
    });

    testWidgets('Add chapter bottom sheet shows form', (
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleChaptersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB to show add chapter bottom sheet
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show add chapter form
      expect(find.text('إضافة باب جديد'), findsOneWidget);
      expect(find.text('عنوان الباب *'), findsOneWidget);
      expect(find.text('تفاصيل (اختياري)'), findsOneWidget);
      expect(find.text('الحالة'), findsOneWidget);
    });

    testWidgets('Add lesson bottom sheet shows form', (
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
            ChangeNotifierProvider<LectureProvider>.value(
              value: lectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhSimpleLessonsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB to show add lesson bottom sheet
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show add lesson form
      expect(find.text('إضافة درس جديد'), findsOneWidget);
      expect(find.text('الفصل/الباب *'), findsOneWidget);
      expect(find.text('عنوان الدرس *'), findsOneWidget);
      expect(find.text('نبذة (اختياري)'), findsOneWidget);
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

  void setCurrentSheikh(Map<String, dynamic> sheikh) {
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

extension LectureProviderTest on LectureProvider {
  void setLectures(List<Map<String, dynamic>> lectures) {
    // This would need to be implemented in the actual LectureProvider
    // for testing purposes
  }
}
