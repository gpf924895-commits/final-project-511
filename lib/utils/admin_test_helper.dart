import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to create test admin accounts in Firestore
/// This is for development/testing purposes only
class AdminTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a test admin account
  /// Call this method to set up test data in Firestore
  static Future<void> createTestAdmin({
    String username = 'admin',
    String password = 'admin123',
    String name = 'Test Admin',
    String email = 'admin@test.com',
    String status = 'active',
    String role = 'admin',
  }) async {
    try {
      // Create document with lowercase ID for case-insensitive lookup
      final docId = username.toLowerCase();
      await _firestore.collection('admins').doc(docId).set({
        'username': username.toLowerCase(), // Store lowercase for consistency
        'password': password,
        'name': name,
        'email': email,
        'status': status,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test admin created: $username (ID: $docId)');
      print('   Document path: admins/$docId');
      print(
        '   Fields: username=$username, password=$password, status=$status',
      );
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
      username: 'supervisor',
      password: 'super123',
      name: 'Supervisor Admin',
      email: 'supervisor@example.com',
      role: 'supervisor',
    );

    await createTestAdmin(
      username: 'testadmin',
      password: 'test123',
      name: 'Test Admin',
      email: 'test@example.com',
      role: 'admin',
    );

    print('✅ All test admins created successfully');
  }

  /// Create test user accounts
  static Future<void> createTestUsers() async {
    try {
      // Create test user 1
      await _firestore.collection('users').doc('user1').set({
        'username': 'user1',
        'password': 'user123',
        'name': 'Test User 1',
        'email': 'user1@example.com',
        'status': 'active',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test user created: user1');

      // Create test user 2
      await _firestore.collection('users').doc('user2').set({
        'username': 'user2',
        'password': 'user456',
        'name': 'Test User 2',
        'email': 'user2@example.com',
        'status': 'active',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test user created: user2');

      print('✅ All test users created successfully');
    } catch (e) {
      print('❌ Error creating test users: $e');
    }
  }

  /// Create both admin and user test accounts
  static Future<void> createAllTestAccounts() async {
    await createTestAdmins();
    await createTestUsers();
    print('✅ All test accounts (admins + users) created successfully');
  }

  /// Verify admin account exists
  static Future<bool> verifyAdminExists(String username) async {
    try {
      final key = username.toLowerCase();
      final doc = await _firestore.collection('admins').doc(key).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error verifying admin: $e');
      return false;
    }
  }

  /// List all admin accounts
  static Future<void> listAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      print('📋 Admin accounts in Firestore:');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('  - ${doc.id}: ${data['name']} (${data['status']})');
      }
    } catch (e) {
      print('❌ Error listing admins: $e');
    }
  }
}
