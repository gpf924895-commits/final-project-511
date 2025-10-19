import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/login_page.dart';
import 'package:new_project/screens/sheikh/sheikh_home_page.dart';
import 'package:new_project/services/sheikh_auth_service.dart';

void main() {
  group('Sheikh Login Integration Tests', () {
    late FirebaseFirestore firestore;
    late SheikhAuthService authService;

    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
      authService = SheikhAuthService();
    });

    setUp(() async {
      // Clean up any existing test data
      await _cleanupTestData(firestore);
    });

    tearDown(() async {
      // Clean up test data after each test
      await _cleanupTestData(firestore);
    });

    testWidgets('Sheikh login with real Firestore data navigates to SheikhHomePage', (
      WidgetTester tester,
    ) async {
      // Create a test Sheikh document in Firestore
      final testSheikhId = '12345678';
      final testPassword = 'testpassword123';
      final testSheikhData = {
        'uid': 'test-sheikh-uid-123',
        'name': 'الشيخ التجريبي',
        'email': 'test-sheikh@example.com',
        'sheikhId': testSheikhId,
        'uniqueId': testSheikhId,
        'role': 'sheikh',
        'category': 'الفقه',
        'secret': testPassword,
        'password': testPassword, // Also store in password field for compatibility
        'status': 'active',
        'isActive': true,
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add the test Sheikh to Firestore
      await firestore
          .collection('users')
          .doc('test-sheikh-uid-123')
          .set(testSheikhData);

      print('[Integration Test] Created test Sheikh document with sheikhId: $testSheikhId');

      // Create a mock AuthProvider for testing
      final authProvider = MockAuthProvider();

      // Build the LoginPage widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: LoginPage(toggleTheme: (isDark) {}),
          ),
          routes: {
            '/sheikh/home': (context) => const SheikhHomePage(),
          },
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Switch to Sheikh tab
      final sheikhTab = find.text('شيخ');
      expect(sheikhTab, findsOneWidget);
      await tester.tap(sheikhTab);
      await tester.pumpAndSettle();

      // Enter the test Sheikh credentials
      final sheikhIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(sheikhIdField, testSheikhId);
      await tester.enterText(passwordField, testPassword);

      // Submit the form
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for authentication to complete
      await tester.pump(const Duration(seconds: 2));

      // Verify that the Sheikh session was set
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.currentRole, 'sheikh');
      expect(authProvider.currentUser?['uniqueId'], testSheikhId);

      // Verify navigation to Sheikh home page
      expect(find.byType(SheikhHomePage), findsOneWidget);
    });

    testWidgets('Sheikh login with invalid credentials shows error', (
      WidgetTester tester,
    ) async {
      // Create a test Sheikh document in Firestore
      final testSheikhId = '87654321';
      final testPassword = 'correctpassword';
      final testSheikhData = {
        'uid': 'test-sheikh-uid-456',
        'name': 'الشيخ التجريبي الثاني',
        'email': 'test-sheikh2@example.com',
        'sheikhId': testSheikhId,
        'uniqueId': testSheikhId,
        'role': 'sheikh',
        'category': 'التفسير',
        'secret': testPassword,
        'status': 'active',
        'isActive': true,
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add the test Sheikh to Firestore
      await firestore
          .collection('users')
          .doc('test-sheikh-uid-456')
          .set(testSheikhData);

      // Create a mock AuthProvider for testing
      final authProvider = MockAuthProvider();

      // Build the LoginPage widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: LoginPage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Sheikh tab
      await tester.tap(find.text('شيخ'));
      await tester.pumpAndSettle();

      // Enter wrong credentials
      final sheikhIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(sheikhIdField, testSheikhId);
      await tester.enterText(passwordField, 'wrongpassword');

      // Submit the form
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for authentication to complete
      await tester.pump(const Duration(seconds: 2));

      // Verify that the Sheikh session was NOT set
      expect(authProvider.isLoggedIn, false);

      // Verify error message is shown
      expect(find.text('رقم الشيخ أو كلمة المرور غير صحيحة'), findsOneWidget);
    });

    testWidgets('Sheikh login with inactive account shows error', (
      WidgetTester tester,
    ) async {
      // Create an inactive test Sheikh document in Firestore
      final testSheikhId = '11111111';
      final testPassword = 'testpassword';
      final testSheikhData = {
        'uid': 'test-sheikh-uid-789',
        'name': 'الشيخ غير النشط',
        'email': 'inactive-sheikh@example.com',
        'sheikhId': testSheikhId,
        'uniqueId': testSheikhId,
        'role': 'sheikh',
        'category': 'الحديث',
        'secret': testPassword,
        'status': 'inactive',
        'isActive': false,
        'enabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add the test Sheikh to Firestore
      await firestore
          .collection('users')
          .doc('test-sheikh-uid-789')
          .set(testSheikhData);

      // Create a mock AuthProvider for testing
      final authProvider = MockAuthProvider();

      // Build the LoginPage widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: LoginPage(toggleTheme: (isDark) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Sheikh tab
      await tester.tap(find.text('شيخ'));
      await tester.pumpAndSettle();

      // Enter credentials
      final sheikhIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(sheikhIdField, testSheikhId);
      await tester.enterText(passwordField, testPassword);

      // Submit the form
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for authentication to complete
      await tester.pump(const Duration(seconds: 2));

      // Verify that the Sheikh session was NOT set
      expect(authProvider.isLoggedIn, false);

      // Verify error message is shown
      expect(find.text('الحساب غير مفعّل'), findsOneWidget);
    });

    test('SheikhAuthService integration with real Firestore data', () async {
      // Create a test Sheikh document
      final testSheikhId = '99999999';
      final testPassword = 'integrationtest123';
      final testSheikhData = {
        'uid': 'test-sheikh-uid-integration',
        'name': 'الشيخ للتكامل',
        'email': 'integration-sheikh@example.com',
        'sheikhId': testSheikhId,
        'uniqueId': testSheikhId,
        'role': 'sheikh',
        'category': 'التوحيد',
        'secret': testPassword,
        'status': 'active',
        'isActive': true,
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add the test Sheikh to Firestore
      await firestore
          .collection('users')
          .doc('test-sheikh-uid-integration')
          .set(testSheikhData);

      // Test authentication with correct credentials
      final result = await authService.authenticateSheikh(testSheikhId, testPassword);

      expect(result['success'], true);
      expect(result['message'], 'تم تسجيل الدخول بنجاح');
      
      final sheikhData = result['sheikh'] as Map<String, dynamic>;
      expect(sheikhData['uid'], 'test-sheikh-uid-integration');
      expect(sheikhData['name'], 'الشيخ للتكامل');
      expect(sheikhData['role'], 'sheikh');
      expect(sheikhData['uniqueId'], testSheikhId);
      expect(sheikhData['isActive'], true);

      // Test authentication with wrong password
      final wrongResult = await authService.authenticateSheikh(testSheikhId, 'wrongpassword');
      expect(wrongResult['success'], false);
      expect(wrongResult['message'], 'رقم الشيخ أو كلمة المرور غير صحيحة');

      // Test authentication with wrong sheikhId
      final wrongIdResult = await authService.authenticateSheikh('00000000', testPassword);
      expect(wrongIdResult['success'], false);
      expect(wrongIdResult['message'], 'رقم الشيخ أو كلمة المرور غير صحيحة');
    });
  });
}

// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isGuest = true;
  bool _isReady = true;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isGuest => _isGuest;

  @override
  bool get isAuthenticated => _isLoggedIn && !_isGuest;

  @override
  bool get isReady => _isReady;

  @override
  Map<String, dynamic>? get currentUser => _currentUser;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get currentUid => _currentUser?['uid'];

  @override
  String? get currentRole => _currentUser?['role'];

  void setSheikhSession(Map<String, dynamic> sheikhData) {
    _currentUser = {
      'uid': sheikhData['uid'],
      'name': sheikhData['name'],
      'email': sheikhData['email'],
      'role': 'sheikh',
      'sheikhId': sheikhData['sheikhId'],
      'category': sheikhData['category'],
      'is_admin': false,
      'status': 'active',
    };
    _isLoggedIn = true;
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

// Helper function to clean up test data
Future<void> _cleanupTestData(FirebaseFirestore firestore) async {
  try {
    // Delete test Sheikh documents
    final testSheikhs = await firestore
        .collection('users')
        .where('role', isEqualTo: 'sheikh')
        .where('email', whereIn: [
          'test-sheikh@example.com',
          'test-sheikh2@example.com',
          'inactive-sheikh@example.com',
          'integration-sheikh@example.com',
        ])
        .get();

    for (final doc in testSheikhs.docs) {
      await doc.reference.delete();
    }
  } catch (e) {
    print('[Cleanup] Error cleaning up test data: $e');
  }
}
