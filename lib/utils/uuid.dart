import 'dart:math';

/// Generate a simple UUID v4-like string
/// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
/// where x is any hexadecimal digit and y is one of 8, 9, A, or B
String generateUUID() {
  final random = Random();
  final hexDigits = '0123456789abcdef';

  String generateHex(int length) {
    return List.generate(
      length,
      (_) => hexDigits[random.nextInt(hexDigits.length)],
    ).join();
  }

  // Format: 8-4-4-4-12
  return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-'
      '${hexDigits[8 + random.nextInt(4)]}${generateHex(3)}-'
      '${generateHex(12)}';
}





