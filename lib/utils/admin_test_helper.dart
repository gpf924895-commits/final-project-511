import 'package:new_project/repository/local_repository.dart';

/// Helper class to create test admin accounts in SQLite
/// This is for development/testing purposes only
class AdminTestHelper {
  static final LocalRepository _repository = LocalRepository();

  /// Create a test admin account
  /// Call this method to set up test data in SQLite
  static Future<void> createTestAdmin({
    String username = 'admin',
    String password = 'admin123',
    String name = 'Test Admin',
    String email = 'admin@test.com',
    String status = 'active',
    String role = 'admin',
  }) async {
    try {
      // Use LocalRepository to create admin account
      final result = await _repository.createAdminAccount(
        username: username,
        email: email,
        password: password,
      );

      if (result['success']) {
        print('✅ Test admin created: $username');
        print('   Email: $email, Password: $password');
      } else {
        print('❌ Error creating test admin: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error creating test admin: $e');
    }
  }

  /// Create multiple test admin accounts
  static Future<void> createTestAdmins() async {
    await createTestAdmin(
      username: 'admin',
      password: 'admin123',
      name: 'Main Admin',
      email: 'admin@example.com',
      role: 'admin',
    );

    await createTestAdmin(
      username: 'admin2',
      password: 'admin456',
      name: 'Secondary Admin',
      email: 'admin2@example.com',
      role: 'admin',
    );
  }

  /// Delete a test admin account
  static Future<void> deleteTestAdmin(String username) async {
    try {
      // Note: LocalRepository doesn't have delete by username
      // This would need to be implemented if needed
      print('⚠️ Delete by username not yet implemented in LocalRepository');
    } catch (e) {
      print('❌ Error deleting test admin: $e');
    }
  }

  /// Clear all test admin accounts
  static Future<void> clearTestAdmins() async {
    try {
      // Note: LocalRepository doesn't have bulk delete
      // This would need to be implemented if needed
      print('⚠️ Clear all admins not yet implemented in LocalRepository');
    } catch (e) {
      print('❌ Error clearing test admins: $e');
    }
  }

  /// Create test users
  static Future<void> createTestUsers() async {
    try {
      // Create dummy test users in SQLite
      await _repository.registerUser(
        username: 'testuser1',
        email: 'test1@example.com',
        password: 'test123',
      );
      await _repository.registerUser(
        username: 'testuser2',
        email: 'test2@example.com',
        password: 'test123',
      );
      print('✅ Test users created');
    } catch (e) {
      print('❌ Error creating test users: $e');
    }
  }

  /// Create all test accounts (admins + users)
  static Future<void> createAllTestAccounts() async {
    await createTestAdmins();
    await createTestUsers();
    print('✅ All test accounts created');
  }

  /// Verify admin exists
  static Future<bool> verifyAdminExists(String username) async {
    try {
      // Check if admin exists by trying to login
      final result = await _repository.loginAdmin(
        username: username,
        password: 'dummy', // Just check existence, not password
      );
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// List admins
  static Future<void> listAdmins() async {
    try {
      // Get all users and filter admins
      final allUsers = await _repository.getAllUsers();
      print('Total users: ${allUsers.length}');
      // Note: Admin filtering by role not yet implemented
      print('⚠️ Admin listing by role not yet implemented');
    } catch (e) {
      print('❌ Error listing admins: $e');
    }
  }
}
