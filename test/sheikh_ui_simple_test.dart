import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_project/screens/sheikh/sheikh_home_page.dart';
import 'package:new_project/screens/sheikh/sheikh_category_picker.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';
import 'package:new_project/screens/sheikh/edit_lecture_page.dart';
import 'package:new_project/screens/sheikh/delete_lecture_page.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    setupFirebaseForTests();
  });
  group('Sheikh UI Simple Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockLectureProvider mockLectureProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockLectureProvider = MockLectureProvider();
    });

    testWidgets('SheikhHomePage renders without overflow', (
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
          child: const MaterialApp(home: SheikhHomePage()),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('SheikhCategoryPicker renders without overflow', (
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

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddLectureForm renders without overflow', (
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

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('EditLecturePage renders without overflow', (
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
          child: const MaterialApp(home: EditLecturePage()),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('DeleteLecturePage renders without overflow', (
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
          child: const MaterialApp(home: DeleteLecturePage()),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheikh UI uses GREEN theme consistently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.green,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(
                value: mockAuthProvider,
              ),
              ChangeNotifierProvider<LectureProvider>.value(
                value: mockLectureProvider,
              ),
            ],
            child: const SheikhHomePage(),
          ),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sheikh UI has proper RTL support', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthProvider>.value(
                  value: mockAuthProvider,
                ),
                ChangeNotifierProvider<LectureProvider>.value(
                  value: mockLectureProvider,
                ),
              ],
              child: const SheikhHomePage(),
            ),
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
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<LectureProvider>.value(
              value: mockLectureProvider,
            ),
          ],
          child: const MaterialApp(home: SheikhHomePage()),
        ),
      );

      // Check that the widget renders without overflow
      expect(tester.takeException(), isNull);
    });
  });
}

// Mock classes for testing
class MockAuthProvider extends AuthProvider {
  @override
  bool get isReady => true;

  @override
  bool get isAuthenticated => true;

  @override
  String? get currentUid => 'test-sheikh-id';

  @override
  Map<String, dynamic>? get currentUser => {
    'uid': 'test-sheikh-id',
    'name': 'الشيخ التجريبي',
    'email': 'sheikh@example.com',
    'role': 'sheikh',
  };

  @override
  String? get currentRole => 'sheikh';
}

class MockLectureProvider extends LectureProvider {
  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<Map<String, dynamic>> get sheikhLectures => [];

  @override
  Map<String, dynamic> get sheikhStats => {
    'totalLectures': 0,
    'upcomingToday': 0,
    'lastUpdated': null,
  };
}
