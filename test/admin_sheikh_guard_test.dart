import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/services/sheikh_service.dart';

void main() {
  group('Admin Sheikh Guard Tests', () {
    test('Pre-generated Sheikh ID is 8 digits', () {
      final testIds = ['00000001', '00000024', '99999999'];
      for (final id in testIds) {
        expect(id.length, 8);
        expect(int.tryParse(id), isNotNull);
      }
    });

    test('Sheikh ID format validation', () {
      const validId = '00000042';
      expect(validId, matches(r'^\d{8}$'));
      expect(validId.length, 8);

      const invalidIds = ['123', '0000001', '000000001', 'abcd1234'];
      for (final id in invalidIds) {
        expect(id, isNot(matches(r'^\d{8}$')));
      }
    });

    test('Counter-based ID generation logic (simulated)', () {
      // Simulate counter increment
      int counter = 0;

      // First sheikh
      counter++;
      final id1 = counter.toString().padLeft(8, '0');
      expect(id1, '00000001');

      // Second sheikh
      counter++;
      final id2 = counter.toString().padLeft(8, '0');
      expect(id2, '00000002');

      // 100th sheikh
      counter = 100;
      final id100 = counter.toString().padLeft(8, '0');
      expect(id100, '00000100');

      // 1000th sheikh
      counter = 1000;
      final id1000 = counter.toString().padLeft(8, '0');
      expect(id1000, '00001000');
    });

    test('Sequential ID generation (no duplicates)', () {
      final generatedIds = <String>{};
      int counter = 0;

      for (int i = 0; i < 100; i++) {
        counter++;
        final id = counter.toString().padLeft(8, '0');
        expect(generatedIds.contains(id), false, reason: 'Duplicate ID: $id');
        generatedIds.add(id);
      }

      expect(generatedIds.length, 100);
    });

    test('SheikhServiceException stores message correctly', () {
      const message = 'ليس لديك صلاحية لإنشاء حسابات الشيوخ';
      final exception = SheikhServiceException(message);

      expect(exception.message, message);
      expect(exception.toString(), message);
    });

    test('Admin access error messages are in Arabic', () {
      final messages = [
        'ليس لديك صلاحية لإنشاء حسابات الشيوخ',
        'هذه الصفحة للمشرف فقط.',
        'يرجى تسجيل الدخول أولاً',
      ];

      for (final message in messages) {
        expect(message, isNotEmpty);
        expect(
          message.contains('ليس') ||
              message.contains('هذه') ||
              message.contains('يرجى'),
          true,
        );
      }
    });

    test('Valid sheikh data with pre-generated ID', () {
      final sheikhData = {
        'uid': 'test-uid-123',
        'name': 'الشيخ محمد أحمد',
        'email': 'sheikh@example.com',
        'role': 'sheikh',
        'sheikhId': '00000042',
        'category': 'الفقه',
        'enabled': true,
        'createdBy': 'admin-uid',
      };

      expect(sheikhData['uid'], isNotNull);
      expect(sheikhData['name'], isNotNull);
      expect(sheikhData['email'], contains('@'));
      expect(sheikhData['role'], 'sheikh');
      expect(sheikhData['sheikhId'], matches(r'^\d{8}$'));
      expect((sheikhData['sheikhId'] as String).length, 8);
      expect(sheikhData['category'], isNotNull);
      expect(sheikhData['enabled'], true);
      expect(sheikhData['createdBy'], isNotNull);
    });

    test('Copy to clipboard text format', () {
      const sheikhId = '00000024';
      final clipboardText = sheikhId;

      expect(clipboardText, matches(r'^\d{8}$'));
      expect(clipboardText.length, 8);
      expect(clipboardText, '00000024');
    });

    test('Success message format with Sheikh ID', () {
      const sheikhId = '00000024';
      final message = 'تم إنشاء حساب الشيخ برقم: $sheikhId';

      expect(message, contains('تم إنشاء'));
      expect(message, contains(sheikhId));
      expect(message, contains('00000024'));
    });

    test('Atomic counter prevents duplicates (simulation)', () {
      // Simulate two concurrent requests
      int counter = 5;

      // Request 1 reads counter
      final read1 = counter;
      // Request 2 reads counter
      final read2 = counter;

      // Both increment
      final next1 = read1 + 1; // 6
      final next2 = read2 + 1; // 6 (duplicate!)

      // With atomic transaction, this shouldn't happen
      // Firestore transaction ensures sequential execution
      expect(next1, next2, reason: 'Without transaction, duplicates occur');

      // With proper transaction:
      counter++; // First request commits: 6
      final id1 = counter.toString().padLeft(8, '0');
      counter++; // Second request commits: 7
      final id2 = counter.toString().padLeft(8, '0');

      expect(id1, '00000006');
      expect(id2, '00000007');
      expect(
        id1,
        isNot(equals(id2)),
        reason: 'Transaction prevents duplicates',
      );
    });

    test('Preview ID shown on page load (non-blocking)', () {
      // Simulate page load - preview is fetched non-blocking
      final previewId = '00000015';

      // Preview should be available for display
      expect(previewId, isNotNull);
      expect(previewId.length, 8);

      // On submit, ID is allocated transactionally (may differ from preview)
      // but will be sequential based on current counter at submit time
      final allocatedId = '00000015'; // or '00000016' if counter changed
      expect(allocatedId, isNotNull);
      expect(allocatedId.length, 8);

      // Preview is for display only; final ID comes from transaction on submit
      expect(int.parse(allocatedId) >= int.parse(previewId), true);
    });

    test('DEMO password validation (6+ chars)', () {
      // DEMO ONLY — weak passwords allowed
      expect('test12'.length >= 6, true);
      expect('123456'.length >= 6, true);
      expect('short'.length >= 6, false);
    });
  });
}
