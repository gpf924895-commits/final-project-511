import 'package:new_project/repository/local_repository.dart';
import 'dart:developer' as developer;

/// Authentication service - Local SQLite implementation
/// All operations use LocalRepository
class AuthService {
  final LocalRepository _repository = LocalRepository();

  /// Get current user - not applicable in offline mode
  dynamic get currentUser => null;

  /// Get current user ID - not applicable in offline mode
  String? get currentUserId => null;

  /// Stream of auth state changes - not applicable in offline mode
  Stream<dynamic> get authStateChanges => Stream.value(null);

  /// Register a new user with email/password
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      return await _repository.registerUser(
        username: username ?? email.split('@')[0],
        email: email,
        password: password,
      );
    } catch (e) {
      developer.log('Register error: $e', name: 'AuthService');
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// Sign in with email/password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _repository.loginUser(email: email, password: password);
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthService');
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// Sign out - not applicable in offline mode
  Future<void> signOut() async {
    // No-op in offline mode
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _repository.changeUserPassword(
        userId: userId,
        oldPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      developer.log('Change password error: $e', name: 'AuthService');
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// Send password reset email - not supported in offline mode
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    return {
      'success': false,
      'message': 'إعادة تعيين كلمة المرور غير مدعومة في الوضع المحلي',
    };
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? username,
    String? name,
    String? gender,
    String? birthDate,
    String? profileImageUrl,
  }) async {
    try {
      return await _repository.updateUserProfile(
        userId: userId,
        name: name,
        gender: gender,
        birthDate: birthDate,
        profileImageUrl: profileImageUrl,
      );
    } catch (e) {
      developer.log('Update profile error: $e', name: 'AuthService');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الملف الشخصي: $e',
      };
    }
  }
}
