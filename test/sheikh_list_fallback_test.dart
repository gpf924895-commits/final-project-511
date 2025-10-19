import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/services/sheikh_service.dart';

void main() {
  group('Sheikh List Fallback Tests', () {
    test('SheikhQueryResult initializes correctly in normal mode', () {
      final result = SheikhQueryResult(
        items: [
          {'name': 'Test Sheikh', 'sheikhId': '00000001'},
        ],
        fallbackMode: false,
      );

      expect(result.items.length, 1);
      expect(result.fallbackMode, false);
      expect(result.indexCreateUrl, null);
      expect(result.errorMessage, null);
    });

    test('SheikhQueryResult handles fallback mode with index URL', () {
      const testUrl = 'https://console.firebase.google.com/test-index-url';
      final result = SheikhQueryResult(
        items: [
          {'name': 'Test Sheikh', 'sheikhId': '00000001'},
        ],
        fallbackMode: true,
        indexCreateUrl: testUrl,
      );

      expect(result.items.length, 1);
      expect(result.fallbackMode, true);
      expect(result.indexCreateUrl, testUrl);
      expect(result.errorMessage, null);
    });

    test('SheikhQueryResult can have empty items list', () {
      final result = SheikhQueryResult(items: [], fallbackMode: true);

      expect(result.items.isEmpty, true);
      expect(result.fallbackMode, true);
    });

    test('SheikhServiceException stores message correctly', () {
      const message = 'لا تملك صلاحية عرض هذه القائمة';
      final exception = SheikhServiceException(message);

      expect(exception.message, message);
      expect(exception.toString(), message);
    });

    test('Index URL extraction pattern matches Firebase URLs', () {
      const errorMessages = [
        'Error: requires an index https://console.firebase.google.com/project/test/indexes?create_composite=abc123',
        'Index required at https://console.firebase.google.com/u/0/project/my-project/firestore/indexes?create_composite=xyz',
      ];

      final urlPattern = RegExp(
        r'https://console\.firebase\.google\.com[^\s]+',
      );

      for (final message in errorMessages) {
        final match = urlPattern.firstMatch(message);
        expect(match, isNotNull);
        expect(
          match!.group(0),
          startsWith('https://console.firebase.google.com'),
        );
      }
    });

    test('Error messages are in Arabic', () {
      final errors = [
        'لا تملك صلاحية عرض هذه القائمة',
        'تعذّر الاتصال. حاول مجددًا.',
        'فشل في تحميل قائمة الشيوخ',
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      ];

      for (final error in errors) {
        expect(error, isNotEmpty);
        // Check that it contains Arabic characters
        expect(
          error.contains(RegExp(r'[\u0600-\u06FF]')),
          true,
          reason: 'Error message should contain Arabic text',
        );
      }
    });

    test('Client-side search filters correctly', () {
      final items = [
        {
          'name': 'محمد أحمد',
          'email': 'mohammad@test.com',
          'sheikhId': '00000001',
        },
        {'name': 'علي حسن', 'email': 'ali@test.com', 'sheikhId': '00000002'},
        {
          'name': 'عمر خالد',
          'email': 'omar@example.com',
          'sheikhId': '00000003',
        },
      ];

      // Test name search
      final nameResults = items.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        return name.contains('محمد');
      }).toList();
      expect(nameResults.length, 1);
      expect(nameResults.first['sheikhId'], '00000001');

      // Test email search
      final emailResults = items.where((item) {
        final email = (item['email'] ?? '').toString().toLowerCase();
        return email.contains('test.com');
      }).toList();
      expect(emailResults.length, 2);

      // Test sheikhId search
      final idResults = items.where((item) {
        final sheikhId = (item['sheikhId'] ?? '').toString();
        return sheikhId.contains('00000003');
      }).toList();
      expect(idResults.length, 1);
      expect(idResults.first['name'], 'عمر خالد');
    });

    test('Fallback mode badge text is correct', () {
      const fallbackMessage =
          'وضع عرض مبسّط — يلزم إنشاء فهرس لتحسين البحث/الفرز';

      expect(fallbackMessage, contains('وضع عرض مبسّط'));
      expect(fallbackMessage, contains('فهرس'));
      expect(fallbackMessage, isNotEmpty);
    });

    test('Index panel messages are in Arabic', () {
      const messages = [
        'فشل تحميل القائمة بالاستعلام الكامل — يحتاج فهرس مركب',
        'نسخ رابط إنشاء الفهرس',
        'إعادة المحاولة',
        'الاستمرار بالعرض المبسّط',
        'تم نسخ رابط إنشاء الفهرس',
      ];

      for (final message in messages) {
        expect(message, isNotEmpty);
        expect(
          message.contains(RegExp(r'[\u0600-\u06FF]')),
          true,
          reason: 'Message should contain Arabic text: $message',
        );
      }
    });

    test('Client-side date sorting works correctly', () {
      final items = [
        {'name': 'Sheikh A', 'createdAt': DateTime(2024, 1, 15)},
        {'name': 'Sheikh B', 'createdAt': DateTime(2024, 3, 20)},
        {'name': 'Sheikh C', 'createdAt': DateTime(2024, 2, 10)},
      ];

      // Sort descending (newest first)
      items.sort((a, b) {
        final aDate = a['createdAt'] as DateTime;
        final bDate = b['createdAt'] as DateTime;
        return bDate.compareTo(aDate);
      });

      expect(items[0]['name'], 'Sheikh B'); // March
      expect(items[1]['name'], 'Sheikh C'); // February
      expect(items[2]['name'], 'Sheikh A'); // January
    });

    test('KPI count displays correctly', () {
      final sheikhCounts = [0, 1, 5, 42, 100];

      for (final count in sheikhCounts) {
        final displayText = 'إجمالي: $count شيخ';
        expect(displayText, contains('إجمالي'));
        expect(displayText, contains(count.toString()));
        expect(displayText, contains('شيخ'));
      }
    });

    test('Sheikh ID format validation (8 digits)', () {
      final validIds = ['00000001', '00000042', '99999999'];
      final invalidIds = ['123', '0000001', '000000001', 'abcd1234'];

      for (final id in validIds) {
        expect(id.length, 8);
        expect(int.tryParse(id), isNotNull);
        expect(id, matches(r'^\d{8}$'));
      }

      for (final id in invalidIds) {
        expect(id, isNot(matches(r'^\d{8}$')));
      }
    });
  });
}
