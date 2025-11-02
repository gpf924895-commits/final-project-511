import 'package:new_project/repository/local_repository.dart';
import 'dart:developer' as developer;
import 'dart:async';

class SheikhServiceException implements Exception {
  final String message;

  SheikhServiceException(this.message);

  @override
  String toString() => message;
}

class SheikhQueryResult {
  final List<Map<String, dynamic>> items;
  final bool fallbackMode;
  final String? indexCreateUrl;
  final String? errorMessage;

  SheikhQueryResult({
    required this.items,
    this.fallbackMode = false,
    this.indexCreateUrl,
    this.errorMessage,
  });
}

/// SheikhService - Local SQLite implementation
/// Provides sheikh management operations
class SheikhService {
  final LocalRepository _repository = LocalRepository();

  /// Preview next Sheikh ID (non-blocking read, no transaction)
  /// Used for display only - actual allocation happens on submit
  Future<String> previewNextSheikhId() async {
    try {
      // For offline-only: Generate ID from timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 100000000).toString().padLeft(8, '0');
    } catch (e) {
      developer.log(
        'Error fetching preview Sheikh ID',
        name: 'SheikhService',
        error: e,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 100000000).toString().padLeft(8, '0');
    }
  }

  /// Allocate next Sheikh ID atomically (transaction-based)
  /// Called ONLY on submit to ensure sequential IDs without duplicates
  Future<String> allocateNextSheikhId() async {
    try {
      // For offline-only: Generate unique ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 100000000).toString().padLeft(8, '0');

      developer.log('Allocated Sheikh ID: $random', name: 'SheikhService');

      return random;
    } on TimeoutException {
      developer.log(
        'Timeout allocating Sheikh ID',
        name: 'SheikhService',
        error: 'Timeout',
      );
      throw SheikhServiceException('انتهت المهلة. حاول مجددًا.');
    } catch (e) {
      developer.log(
        'Error allocating Sheikh ID',
        name: 'SheikhService',
        error: e,
      );
      throw SheikhServiceException('فشل في تخصيص رقم الشيخ: $e');
    }
  }

  /// Register a new Sheikh
  /// TODO: Implement sheikh registration in LocalRepository
  Future<Map<String, dynamic>> registerSheikh({
    required String sheikhId,
    required String name,
    required String email,
    required String password,
    String? category,
    String? phone,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Use LocalRepository to register user with sheikh role
      // Note: LocalRepository.registerUser doesn't support role parameter yet
      // For now, create user and update role manually
      final result = await _repository.registerUser(
        username: sheikhId,
        email: email,
        password: password,
      );

      if (!result['success']) {
        return {
          'success': false,
          'message': result['message'] ?? 'فشل في تسجيل الشيخ',
        };
      }

      // Update user to add sheikh-specific fields
      final userId = result['user_id'] as String;
      final userProfile = await _repository.getUserProfile(userId);
      if (userProfile == null) {
        return {
          'success': false,
          'message': 'فشل في الحصول على بيانات المستخدم',
        };
      }

      return {
        'success': true,
        'message': 'تم تسجيل الشيخ بنجاح',
        'sheikh': {
          'id': userId,
          'sheikhId': sheikhId,
          'name': name,
          'email': email,
          'uniqueId': sheikhId,
          'role': 'sheikh',
        },
      };
    } catch (e) {
      developer.log(
        'Error registering sheikh',
        name: 'SheikhService',
        error: e,
      );
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الشيخ: $e'};
    }
  }

  /// List all sheikhs
  /// TODO: Filter by role in LocalRepository
  Future<SheikhQueryResult> listSheikhs({
    String? search,
    String? category,
    bool? isActive,
    int limit = 50,
  }) async {
    try {
      // For offline-only: Get all users and filter by role
      // Note: LocalRepository doesn't have role filtering yet
      // Return empty for now - needs users table to have role field
      return SheikhQueryResult(items: []);
    } catch (e) {
      developer.log('Error listing sheikhs', name: 'SheikhService', error: e);
      return SheikhQueryResult(
        items: [],
        errorMessage: 'فشل في تحميل قائمة الشيوخ: $e',
      );
    }
  }

  /// Get sheikh by ID
  Future<Map<String, dynamic>?> getSheikh(String sheikhId) async {
    try {
      return await _repository.getUserByUniqueId(sheikhId, role: 'sheikh');
    } catch (e) {
      developer.log('Error getting sheikh', name: 'SheikhService', error: e);
      return null;
    }
  }

  /// Update sheikh information
  /// TODO: Implement in LocalRepository
  Future<void> updateSheikh({
    required String sheikhId,
    String? name,
    String? email,
    String? category,
    String? phone,
    Map<String, dynamic>? additionalData,
  }) async {
    throw SheikhServiceException(
      'تحديث بيانات الشيوخ غير مدعوم حالياً في الوضع المحلي',
    );
  }

  /// Delete sheikh (soft delete)
  Future<void> deleteSheikh(String sheikhId) async {
    try {
      final sheikh = await _repository.getUserByUniqueId(
        sheikhId,
        role: 'sheikh',
      );
      if (sheikh == null) {
        throw SheikhServiceException('الشيخ غير موجود');
      }

      final uid = sheikh['uid'] as String;
      await _repository.archiveLecturesBySheikh(uid);
      // Optionally delete user: await _repository.deleteUser(uid);
    } catch (e) {
      developer.log('Error deleting sheikh', name: 'SheikhService', error: e);
      throw SheikhServiceException('فشل في حذف الشيخ: $e');
    }
  }

  /// Count total sheikhs
  Future<int> countSheikhs() async {
    try {
      return await _repository.countSheikhs();
    } catch (e) {
      developer.log('Error counting sheikhs', name: 'SheikhService', error: e);
      return 0;
    }
  }

  /// Create a new sheikh (called by admin_add_sheikh_page.dart)
  Future<Map<String, dynamic>> createSheikh({
    required String name,
    String? email,
    String? password,
    String? category,
    String? phone,
    String? currentAdminUid,
  }) async {
    try {
      // Allocate unique ID
      final uniqueId = await allocateNextSheikhId();

      // Create sheikh in sheikhs table
      final result = await _repository.createSheikh(
        name: name,
        email: email,
        phone: phone,
        uniqueId: uniqueId,
        category: category,
      );

      if (!result['success']) {
        return result;
      }

      // If password is provided, also create a user account for login
      if (password != null &&
          password.isNotEmpty &&
          email != null &&
          email.isNotEmpty) {
        final userResult = await _repository.registerUser(
          username: uniqueId,
          email: email,
          password: password,
        );

        if (userResult['success']) {
          // Update user to add uniqueId and role
          final userId = userResult['user_id'] as String;
          await _repository.updateUserRoleAndUniqueId(
            userId: userId,
            uniqueId: uniqueId,
            role: 'sheikh',
            name: name,
          );
        }
      }

      return {
        'success': true,
        'message': 'تم إنشاء حساب الشيخ بنجاح',
        'sheikhId': uniqueId,
        'id': result['id'],
      };
    } catch (e) {
      developer.log('Error creating sheikh', name: 'SheikhService', error: e);
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الشيخ: $e'};
    }
  }
}
