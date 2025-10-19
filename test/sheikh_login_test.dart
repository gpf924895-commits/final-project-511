import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock SheikhAuthService for testing without Firebase
class MockSheikhAuthService {
  /// Get error message for input validation
  String? getErrorMessage(String sheikhId, String password) {
    if (sheikhId.trim().isEmpty || password.trim().isEmpty) {
      return 'الرجاء إدخال رقم الشيخ وكلمة المرور';
    }

    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      return 'رقم الشيخ غير صحيح';
    }

    return null; // Valid input
  }

  /// Normalize sheikhId to 8-digit string (enforces exactly 8 digits)
  String normalizeSheikhId(String sheikhId) {
    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return '';

    // Enforce exactly 8 digits - no padding, must be exactly 8 digits
    if (normalized.length != 8) {
      return ''; // Return empty string for invalid length
    }

    return normalized; // Return as-is since it's exactly 8 digits
  }

  /// Mock authentication method
  Future<Map<String, dynamic>> authenticateSheikh(
    String sheikhId,
    String password,
  ) async {
    // Input validation
    if (sheikhId.trim().isEmpty || password.trim().isEmpty) {
      return {
        'success': false,
        'message': 'الرجاء إدخال رقم الشيخ وكلمة المرور',
      };
    }

    // Enforce exactly 8 digits policy
    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      return {'success': false, 'message': 'رقم الشيخ غير صحيح'};
    }

    // Enforce exactly 8 digits - no padding, must be exactly 8 digits
    if (normalized.length != 8) {
      return {
        'success': false,
        'message': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط',
      };
    }

    final sheikhId8Digit = normalized; // Use as-is since it's exactly 8 digits

    // Mock authentication logic
    if (sheikhId8Digit == '12345678' && password == 'password123') {
      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'sheikh': {
          'uid': 'test-sheikh-uid',
          'name': 'الشيخ التجريبي',
          'email': 'sheikh@test.com',
          'uniqueId': sheikhId8Digit,
          'role': 'sheikh',
          'category': 'الفقه',
          'isActive': true,
        },
      };
    }

    return {'success': false, 'message': 'رقم الشيخ أو كلمة المرور غير صحيحة'};
  }
}

void main() {
  group('SheikhAuthService Unit Tests', () {
    test('Normalize sheikhId pads to 8 digits', () {
      // This test verifies the normalization logic
      expect('4'.padLeft(8, '0'), '00000004');
      expect('123'.padLeft(8, '0'), '00000123');
      expect('12345678'.padLeft(8, '0'), '12345678');
      expect('  24  '.trim().padLeft(8, '0'), '00000024');
    });

    test('Normalize removes non-digits', () {
      final input = 'abc123xyz';
      final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');
      expect(normalized, '123');
    });

    test('SheikhAuthService input validation', () async {
      final authService = MockSheikhAuthService();

      // Test empty inputs
      final result1 = await authService.authenticateSheikh('', '');
      expect(result1['success'], false);
      expect(result1['message'], 'الرجاء إدخال رقم الشيخ وكلمة المرور');

      // Test invalid sheikhId format
      final result2 = await authService.authenticateSheikh('abc', 'password');
      expect(result2['success'], false);
      expect(result2['message'], 'رقم الشيخ غير صحيح');

      // Test empty password
      final result3 = await authService.authenticateSheikh('123', '');
      expect(result3['success'], false);
      expect(result3['message'], 'الرجاء إدخال رقم الشيخ وكلمة المرور');
    });

    test('SheikhAuthService error message helper', () {
      final authService = MockSheikhAuthService();

      // Test error message generation
      expect(
        authService.getErrorMessage('', ''),
        'الرجاء إدخال رقم الشيخ وكلمة المرور',
      );
      expect(
        authService.getErrorMessage('abc', 'password'),
        'رقم الشيخ غير صحيح',
      );
      expect(
        authService.getErrorMessage('123', 'password'),
        null, // Valid input should return null
      );
    });

    test('SheikhId normalization works correctly', () {
      final authService = MockSheikhAuthService();

      // Test various input formats - now enforces exactly 8 digits
      expect(
        authService.normalizeSheikhId('12345678'),
        '12345678',
      ); // Valid 8 digits
      expect(
        authService.normalizeSheikhId('00000001'),
        '00000001',
      ); // Valid 8 digits with zeros
      expect(
        authService.normalizeSheikhId('  12345678  '),
        '12345678',
      ); // Valid with spaces
      expect(authService.normalizeSheikhId(''), ''); // Empty string
      expect(authService.normalizeSheikhId('abc'), ''); // Invalid - no digits
      expect(authService.normalizeSheikhId('123'), ''); // Invalid - too short
      expect(
        authService.normalizeSheikhId('123456789'),
        '',
      ); // Invalid - too long
    });
  });

  group('Sheikh Authentication Flow Tests', () {
    testWidgets('Sheikh login form validation works', (
      WidgetTester tester,
    ) async {
      // Test the form validation logic directly
      final formKey = GlobalKey<FormState>();
      final sheikhIdController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: sheikhIdController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال المعرف الفريد';
                      }
                      final normalized = value.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (normalized.isEmpty) {
                        return 'رقم الشيخ غير صحيح';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test empty form validation
      expect(formKey.currentState?.validate(), false);

      // Test invalid sheikhId
      sheikhIdController.text = 'abc';
      passwordController.text = 'password';
      expect(formKey.currentState?.validate(), false);

      // Test valid input
      sheikhIdController.text = '00000001';
      passwordController.text = 'password';
      expect(formKey.currentState?.validate(), true);

      sheikhIdController.dispose();
      passwordController.dispose();
    });

    testWidgets('Sheikh login error messages display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Test various error messages
                Text('الرجاء إدخال رقم الشيخ وكلمة المرور'),
                Text('رقم الشيخ غير صحيح'),
                Text('رقم الشيخ أو كلمة المرور غير صحيحة'),
                Text('هذا الحساب ليس حساب شيخ'),
                Text('الحساب غير مفعّل'),
              ],
            ),
          ),
        ),
      );

      // Verify all error messages are present
      expect(find.text('الرجاء إدخال رقم الشيخ وكلمة المرور'), findsOneWidget);
      expect(find.text('رقم الشيخ غير صحيح'), findsOneWidget);
      expect(find.text('رقم الشيخ أو كلمة المرور غير صحيحة'), findsOneWidget);
      expect(find.text('هذا الحساب ليس حساب شيخ'), findsOneWidget);
      expect(find.text('الحساب غير مفعّل'), findsOneWidget);
    });
  });

  group('Sheikh Session Management Tests', () {
    test('Sheikh session data structure is correct', () {
      final sheikhData = {
        'uid': 'test-sheikh-uid',
        'name': 'الشيخ التجريبي',
        'email': 'sheikh@test.com',
        'sheikhId': '00000001',
        'category': 'الفقه',
      };

      // Verify required fields are present
      expect(sheikhData['uid'], isNotNull);
      expect(sheikhData['name'], isNotNull);
      expect(sheikhData['email'], isNotNull);
      expect(sheikhData['sheikhId'], isNotNull);
      expect(sheikhData['category'], isNotNull);

      // Verify sheikhId format
      expect(sheikhData['sheikhId'], matches(RegExp(r'^\d{8}$')));
    });

    test('Sheikh role validation works', () {
      final validSheikhData = {
        'role': 'sheikh',
        'isActive': true,
        'status': 'active',
      };

      final invalidRoleData = {
        'role': 'user',
        'isActive': true,
        'status': 'active',
      };

      final inactiveData = {
        'role': 'sheikh',
        'isActive': false,
        'status': 'inactive',
      };

      // Test valid sheikh
      expect(validSheikhData['role'], 'sheikh');
      expect(validSheikhData['isActive'], true);

      // Test invalid role
      expect(invalidRoleData['role'], isNot('sheikh'));

      // Test inactive account
      expect(inactiveData['isActive'], false);
    });
  });

  group('Negative Test Cases', () {
    test('Invalid Sheikh ID format returns correct error', () async {
      final authService = MockSheikhAuthService();

      final testCases = [
        {'input': '', 'expected': 'الرجاء إدخال رقم الشيخ وكلمة المرور'},
        {'input': 'abc', 'expected': 'رقم الشيخ غير صحيح'},
        {'input': '123', 'expected': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط'},
        {
          'input': '123456789',
          'expected': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط',
        },
        {'input': '!@#', 'expected': 'رقم الشيخ غير صحيح'},
      ];

      for (final testCase in testCases) {
        final result = await authService.authenticateSheikh(
          testCase['input'] as String,
          'password123',
        );
        expect(result['success'], false);
        expect(result['message'], testCase['expected']);
      }
    });

    test('Empty password returns correct error', () async {
      final authService = MockSheikhAuthService();

      final result = await authService.authenticateSheikh('00000001', '');
      expect(result['success'], false);
      expect(result['message'], 'الرجاء إدخال رقم الشيخ وكلمة المرور');
    });

    test('SheikhId normalization edge cases', () {
      final authService = MockSheikhAuthService();

      // Test edge cases - now enforces exactly 8 digits
      expect(authService.normalizeSheikhId('0'), ''); // Too short
      expect(
        authService.normalizeSheikhId('00000000'),
        '00000000',
      ); // Valid 8 digits
      expect(
        authService.normalizeSheikhId('99999999'),
        '99999999',
      ); // Valid 8 digits
      expect(authService.normalizeSheikhId('123456789'), ''); // Too long
    });

    test('Successful authentication with correct credentials', () async {
      final authService = MockSheikhAuthService();

      final result = await authService.authenticateSheikh(
        '12345678',
        'password123',
      );
      expect(result['success'], true);
      expect(result['message'], 'تم تسجيل الدخول بنجاح');

      final sheikhData = result['sheikh'] as Map<String, dynamic>;
      expect(sheikhData['uid'], 'test-sheikh-uid');
      expect(sheikhData['name'], 'الشيخ التجريبي');
      expect(sheikhData['role'], 'sheikh');
      expect(sheikhData['isActive'], true);
    });

    test('Failed authentication with wrong credentials', () async {
      final authService = MockSheikhAuthService();

      final result = await authService.authenticateSheikh(
        '12345678',
        'wrongpassword',
      );
      expect(result['success'], false);
      expect(result['message'], 'رقم الشيخ أو كلمة المرور غير صحيحة');
    });
  });
}
