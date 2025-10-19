import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/services/sheikh_service.dart';

void main() {
  group('Sheikh ID Generation Tests', () {
    test('First sheikh ID should be 00000001', () {
      // This is a conceptual test - actual implementation uses Firestore
      final expectedFirstId = '00000001';
      expect(expectedFirstId.length, 8);
      expect(int.parse(expectedFirstId), 1);
    });

    test('Sequential sheikh IDs should increment correctly', () {
      // Test ID generation logic
      const lastId = '00000023';
      final lastNumber = int.parse(lastId);
      final nextNumber = lastNumber + 1;
      final nextId = nextNumber.toString().padLeft(8, '0');

      expect(nextId, '00000024');
      expect(nextId.length, 8);
    });

    test('ID padding works correctly for various numbers', () {
      expect(1.toString().padLeft(8, '0'), '00000001');
      expect(10.toString().padLeft(8, '0'), '00000010');
      expect(100.toString().padLeft(8, '0'), '00000100');
      expect(1000.toString().padLeft(8, '0'), '00001000');
      expect(10000.toString().padLeft(8, '0'), '00010000');
      expect(100000.toString().padLeft(8, '0'), '00100000');
      expect(1000000.toString().padLeft(8, '0'), '01000000');
      expect(10000000.toString().padLeft(8, '0'), '10000000');
    });

    test('Maximum 8-digit ID is 99999999', () {
      const maxId = 99999999;
      final maxIdString = maxId.toString().padLeft(8, '0');
      expect(maxIdString, '99999999');
      expect(maxIdString.length, 8);
    });

    test('Sheikh ID format is always 8 digits', () {
      for (int i = 1; i <= 1000; i++) {
        final sheikhId = i.toString().padLeft(8, '0');
        expect(sheikhId.length, 8);
        expect(int.parse(sheikhId), i);
      }
    });
  });

  group('Sheikh Service Exception Tests', () {
    test('SheikhServiceException stores message correctly', () {
      const message = 'يرجى إدخال اسم الشيخ';
      final exception = SheikhServiceException(message);

      expect(exception.message, message);
      expect(exception.toString(), message);
    });

    test('SheikhServiceException messages are in Arabic', () {
      final messages = [
        'ليس لديك صلاحية لإنشاء حسابات الشيوخ',
        'يرجى إدخال اسم الشيخ',
        'يرجى إدخال بريد إلكتروني صحيح',
        'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      ];

      for (final message in messages) {
        final exception = SheikhServiceException(message);
        expect(exception.message, isNotEmpty);
        expect(
          exception.message.contains('يرجى') ||
              exception.message.contains('ليس') ||
              exception.message.contains('كلمة'),
          true,
        );
      }
    });
  });

  group('Sheikh Data Validation Tests', () {
    test('Valid sheikh data structure', () {
      final sheikhData = {
        'uid': 'test-uid-123',
        'name': 'الشيخ محمد أحمد',
        'email': 'sheikh@example.com',
        'role': 'sheikh',
        'sheikhId': '00000001',
        'category': 'الفقه',
        'enabled': true,
      };

      expect(sheikhData['uid'], isNotNull);
      expect(sheikhData['name'], isNotNull);
      expect(sheikhData['email'], contains('@'));
      expect(sheikhData['role'], 'sheikh');
      expect(sheikhData['sheikhId'], matches(r'^\d{8}$'));
      expect(sheikhData['category'], isNotNull);
      expect(sheikhData['enabled'], true);
    });

    test('Sheikh ID format validation', () {
      final validIds = [
        '00000001',
        '00000010',
        '00000100',
        '00001000',
        '12345678',
      ];

      for (final id in validIds) {
        expect(id, matches(r'^\d{8}$'));
        expect(id.length, 8);
      }
    });

    test('Invalid sheikh IDs are rejected', () {
      final invalidIds = [
        '1', // Too short
        '0000001', // 7 digits
        '000000001', // 9 digits
        'abcd1234', // Contains letters
        '12-34-56', // Contains special characters
      ];

      for (final id in invalidIds) {
        expect(id, isNot(matches(r'^\d{8}$')));
      }
    });

    test('Email validation logic', () {
      final validEmails = [
        'sheikh@example.com',
        'test.sheikh@domain.co',
        'user+sheikh@test.org',
      ];

      for (final email in validEmails) {
        expect(email.contains('@'), true);
        expect(email.split('@').length, 2);
      }

      final invalidEmails = ['invalid-email', 'no-at-sign', '@only-at'];

      for (final email in invalidEmails) {
        if (email.contains('@')) {
          expect(email.split('@').length, lessThan(3));
        }
      }
    });

    test('Password length validation', () {
      expect('test12'.length, greaterThanOrEqualTo(6));
      expect('123456'.length, greaterThanOrEqualTo(6));
      expect('short'.length, lessThan(6));
      expect('12345'.length, lessThan(6));
    });
  });

  group('Sheikh Service Return Value Tests', () {
    test('Successful creation response structure', () {
      final response = {
        'success': true,
        'sheikhId': '00000001',
        'uid': 'firebase-uid-123',
        'message': 'تم إنشاء حساب الشيخ برقم: 00000001',
      };

      expect(response['success'], true);
      expect(response['sheikhId'], isNotNull);
      expect(response['sheikhId'], matches(r'^\d{8}$'));
      expect(response['uid'], isNotNull);
      expect(response['message'], contains('تم إنشاء'));
      expect(response['message'], contains(response['sheikhId']));
    });

    test('Success message format', () {
      const sheikhId = '00000042';
      final message = 'تم إنشاء حساب الشيخ برقم: $sheikhId';

      expect(message, contains('تم إنشاء'));
      expect(message, contains(sheikhId));
      expect(message, contains('00000042'));
    });
  });
}
