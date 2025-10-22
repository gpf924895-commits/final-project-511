import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/screens/sheikh/sheikh_category_picker.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';

void main() {
  group('Simple Sheikh Tests', () {
    testWidgets('Category Picker displays all four categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const SheikhCategoryPicker())),
      );

      await tester.pumpAndSettle();

      // Verify all four categories are displayed
      expect(find.text('الفقه'), findsOneWidget);
      expect(find.text('السيرة'), findsOneWidget);
      expect(find.text('التفسير'), findsOneWidget);
      expect(find.text('الحديث'), findsOneWidget);
    });

    testWidgets('Add Lecture Form renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const AddLectureForm())),
      );

      await tester.pumpAndSettle();

      // Verify form is displayed
      expect(find.text('إضافة محاضرة'), findsOneWidget);
    });

    testWidgets('Category Picker has proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const SheikhCategoryPicker())),
      );

      await tester.pumpAndSettle();

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Add Lecture Form has proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const AddLectureForm())),
      );

      await tester.pumpAndSettle();

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });
  });
}
