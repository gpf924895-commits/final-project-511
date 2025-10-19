import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    setupFirebaseForTests();
  });

  group('Basic UI Tests', () {
    testWidgets('Basic widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(body: Center(child: Text('Test Widget'))),
        ),
      );

      // Check that the widget renders
      expect(find.text('Test Widget'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('MaterialApp renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test App')),
              body: const Center(child: Text('Hello World')),
            ),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('SafeArea widget works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SafeArea(child: Center(child: Text('Safe Area Test'))),
        ),
      );

      expect(find.text('Safe Area Test'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('ScrollView widget works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          const SingleChildScrollView(
            child: Column(
              children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
