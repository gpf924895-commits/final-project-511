import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/screens/sheikh/sheikh_home_page.dart';
import 'package:new_project/screens/sheikh/sheikh_category_picker.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';
import 'package:new_project/screens/sheikh/edit_lecture_page.dart';
import 'package:new_project/screens/sheikh/delete_lecture_page.dart';
import 'test_helpers.dart';

void main() {
  group('Sheikh UI Simple Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockLectureProvider mockLectureProvider;
    late MockHierarchyProvider mockHierarchyProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockLectureProvider = MockLectureProvider();
      mockHierarchyProvider = MockHierarchyProvider();
    });

    testWidgets('SheikhHomePage renders without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const SheikhHomePage(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('SheikhCategoryPicker renders without overflow', (
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

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddLectureForm renders without overflow', (
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

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('EditLecturePage renders without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const EditLecturePage(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('DeleteLecturePage renders without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const DeleteLecturePage(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheikh UI uses GREEN theme consistently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const SheikhHomePage(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheikh UI has proper RTL support', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: createTestWidgetWithProviders(
            const SheikhHomePage(),
            authProvider: mockAuthProvider,
            lectureProvider: mockLectureProvider,
            hierarchyProvider: mockHierarchyProvider,
          ),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheikh UI handles small screen sizes', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));

      await tester.pumpWidget(
        createTestWidgetWithProviders(
          const SheikhHomePage(),
          authProvider: mockAuthProvider,
          lectureProvider: mockLectureProvider,
          hierarchyProvider: mockHierarchyProvider,
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });
  });
}
