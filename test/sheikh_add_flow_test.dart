import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/screens/sheikh/sheikh_category_picker.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/lecture_provider.dart';

void main() {
  group('Sheikh Add Flow Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockLectureProvider mockLectureProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockLectureProvider = MockLectureProvider();
    });

    testWidgets('Category Picker displays all four categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhCategoryPicker()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all four categories are displayed
      expect(find.text('الفقه'), findsOneWidget);
      expect(find.text('السيرة'), findsOneWidget);
      expect(find.text('التفسير'), findsOneWidget);
      expect(find.text('الحديث'), findsOneWidget);

      // Verify descriptions are shown
      expect(find.text('أحكام الشريعة الإسلامية'), findsOneWidget);
      expect(find.text('سيرة النبي صلى الله عليه وسلم'), findsOneWidget);
      expect(find.text('تفسير القرآن الكريم'), findsOneWidget);
      expect(find.text('أحاديث النبي صلى الله عليه وسلم'), findsOneWidget);
    });

    testWidgets('Category selection navigates to Add Lecture Form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhCategoryPicker()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on الفقه category
      await tester.tap(find.text('الفقه'));
      await tester.pumpAndSettle();

      // Verify AddLectureForm is displayed
      expect(find.byType(AddLectureForm), findsOneWidget);
    });

    testWidgets('Add Lecture Form shows prefilled category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(
            home: AddLectureForm(categoryKey: 'fiqh', categoryNameAr: 'الفقه'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category is prefilled
      expect(find.text('إضافة محاضرة - الفقه'), findsOneWidget);
      expect(find.text('الفقه'), findsOneWidget);
    });

    testWidgets('Add Lecture Form validates required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(
            home: AddLectureForm(categoryKey: 'fiqh', categoryNameAr: 'الفقه'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('يرجى تحديد وقت البداية'), findsOneWidget);
    });

    testWidgets('Add Lecture Form validates future start time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(
            home: AddLectureForm(categoryKey: 'fiqh', categoryNameAr: 'الفقه'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill title field
      await tester.enterText(
        find.byType(TextFormField).first,
        'محاضرة تجريبية',
      );

      // Set past date and time
      await tester.tap(find.text('اختيار التاريخ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('اختيار الوقت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify future time validation
      expect(find.text('يجب أن يكون وقت البداية في المستقبل'), findsOneWidget);
    });

    testWidgets('Add Lecture Form validates URL format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(
            home: AddLectureForm(categoryKey: 'fiqh', categoryNameAr: 'الفقه'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill title field
      await tester.enterText(
        find.byType(TextFormField).first,
        'محاضرة تجريبية',
      );

      // Set future date and time
      await tester.tap(find.text('اختيار التاريخ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('اختيار الوقت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enter invalid URL
      await tester.enterText(find.text('رابط الصوت (اختياري)'), 'invalid-url');

      // Try to save
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify URL validation
      expect(find.text('صيغة رابط الصوت غير صحيحة'), findsOneWidget);
    });
  });
}

// Mock classes for testing
class MockAuthProvider extends AuthProvider {
  @override
  String? get currentUid => 'test-sheikh-id';

  @override
  Map<String, dynamic>? get currentUser => {
    'uid': 'test-sheikh-id',
    'name': 'الشيخ التجريبي',
    'email': 'test@example.com',
    'role': 'sheikh',
  };

  @override
  bool get isAuthenticated => true;
}

class MockLectureProvider extends LectureProvider {
  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> addSheikhLecture({
    required String sheikhId,
    required String sheikhName,
    required String categoryKey,
    required String categoryNameAr,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    // Mock successful save
    return true;
  }
}
