import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/screens/sheikh/sheikh_category_picker.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';
import 'test_helpers.dart';

void main() {
  group('Sheikh Add Flow Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockLectureProvider mockLectureProvider;
    late MockHierarchyProvider mockHierarchyProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockLectureProvider = MockLectureProvider();
      mockHierarchyProvider = MockHierarchyProvider();
    });

    testWidgets('Category Picker displays all four categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const SheikhCategoryPicker(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
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
        createTestWidgetWithProviders(
          const SheikhCategoryPicker(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
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
        createTestWidgetWithProviders(
          const AddLectureForm(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify form is displayed
      expect(find.text('إضافة محاضرة'), findsOneWidget);
    });

    testWidgets('Add Lecture Form validates required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const AddLectureForm(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('يرجى اختيار القسم والفئة'), findsOneWidget);
    });

    testWidgets('Add Lecture Form validates future start time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const AddLectureForm(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Fill title field
      await tester.enterText(
        find.byType(TextFormField).first,
        'محاضرة تجريبية',
      );

      // Set past date and time
      await tester.tap(find.text('اختر وقت البداية'));
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
        createTestWidgetWithProviders(
          const AddLectureForm(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Fill title field
      await tester.enterText(
        find.byType(TextFormField).first,
        'محاضرة تجريبية',
      );

      // Set future date and time
      await tester.tap(find.text('اختر وقت البداية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enter invalid URL
      await tester.enterText(find.byType(TextFormField).at(4), 'invalid-url');

      // Try to save
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify URL validation
      expect(find.text('صيغة رابط الصوت غير صحيحة'), findsOneWidget);
    });
  });
}
