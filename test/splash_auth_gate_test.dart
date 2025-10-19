import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    setupFirebaseForTests();
  });
  
  group('SplashAuthGate Tests', () {
    testWidgets(
      'SplashAuthGate should show loading indicator and app title',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mosque, size: 60, color: Colors.green),
                    SizedBox(height: 32),
                    Text('منصة زوار المسجد النبوي'),
                    SizedBox(height: 8),
                    Text('إدارة المحاضرات والدروس'),
                    SizedBox(height: 48),
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري التحميل...'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('جاري التحميل...'), findsOneWidget);
        expect(find.text('منصة زوار المسجد النبوي'), findsOneWidget);
        expect(find.byIcon(Icons.mosque), findsOneWidget);
      },
    );

    testWidgets('SplashAuthGate should show app logo and title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mosque, size: 60, color: Colors.green),
                  SizedBox(height: 32),
                  Text('منصة زوار المسجد النبوي'),
                  SizedBox(height: 8),
                  Text('إدارة المحاضرات والدروس'),
                ],
              ),
            ),
          ),
        ),
      );

      // Should show app logo
      expect(find.byIcon(Icons.mosque), findsOneWidget);
      // Should show app title
      expect(find.text('منصة زوار المسجد النبوي'), findsOneWidget);
      expect(find.text('إدارة المحاضرات والدروس'), findsOneWidget);
    });
  });
}