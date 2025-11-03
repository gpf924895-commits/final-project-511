import 'package:new_project/repository/local_repository.dart';

/// SheikhAuthService - Local SQLite implementation
/// Authenticates Sheikh using uniqueId and password
class SheikhAuthService {
  final LocalRepository _repository = LocalRepository();

  /// Authenticate Sheikh using ONLY sheikhId and password
  /// No email dependency - direct database validation
  Future<Map<String, dynamic>> authenticateSheikh(
    String sheikhId,
    String password,
  ) async {
    try {
      print('[SheikhAuthService] Authenticating sheikh with ID: $sheikhId');

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

      final sheikhId8Digit =
          normalized; // Use as-is since it's exactly 8 digits

      print('[SheikhAuthService] Using 8-digit sheikhId: $sheikhId8Digit');

      // Use loginSheikh method which queries sheikhs table only
      final sheikh = await _repository.loginSheikh(sheikhId8Digit, password);

      if (sheikh == null) {
        print('[SheikhAuthService] Login failed for sheikhId: $sheikhId8Digit');
        return {
          'success': false,
          'message': 'رقم الشيخ أو كلمة المرور غير صحيحة',
        };
      }

      print(
        '[SheikhAuthService] Authentication successful for sheikhId: $sheikhId8Digit',
      );

      // Success - return Sheikh data
      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'sheikh': {
          'uid': sheikh['uid'] ?? sheikh['id'],
          'name': sheikh['name'] ?? 'غير محدد',
          'email': sheikh['email'],
          'uniqueId': sheikhId8Digit,
          'sheikhId': sheikhId8Digit,
          'role': 'sheikh',
          'category': sheikh['category'] ?? '',
          'isActive': true, // For offline, assume active
        },
      };
    } catch (e) {
      print('[SheikhAuthService] Error during authentication: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول'};
    }
  }

  /// Validate input format
  String? getErrorMessage(String sheikhId, String password) {
    if (sheikhId.trim().isEmpty || password.trim().isEmpty) {
      return 'الرجاء إدخال رقم الشيخ وكلمة المرور';
    }

    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      return 'رقم الشيخ غير صحيح';
    }

    if (normalized.length != 8) {
      return 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط';
    }

    return null;
  }

  /// Legacy method for backward compatibility
  Future<bool> validateSheikh(String sheikhId, String password) async {
    final result = await authenticateSheikh(sheikhId, password);
    return result['success'] == true;
  }

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>> validateSheikhDetailed(
    String sheikhId,
    String password,
  ) async {
    return await authenticateSheikh(sheikhId, password);
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
}
