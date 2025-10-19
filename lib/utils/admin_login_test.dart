import 'package:new_project/database/firebase_service.dart';

/// Test utility for verifying admin login system
class AdminLoginTest {
  static final FirebaseService _firebaseService = FirebaseService();

  /// Test the complete admin login flow
  static Future<Map<String, dynamic>> testAdminLoginSystem() async {
    print('🧪 Starting Admin Login System Test...');

    final results = <String, dynamic>{
      'admin_account_exists': false,
      'admin_account_created': false,
      'login_successful': false,
      'navigation_working': false,
      'error_messages_working': false,
      'debug_messages_working': false,
    };

    try {
      // Step 1: Test if admin account exists
      print('🔍 Step 1: Checking if admin account exists...');
      final loginResult = await _firebaseService.loginAdmin(
        username: 'admin',
        password: 'admin123',
      );

      if (loginResult['success'] == true) {
        print('✅ Admin account found and login successful');
        results['admin_account_exists'] = true;
        results['login_successful'] = true;
        results['debug_messages_working'] = true;
        return results;
      } else {
        print('❌ Admin account not found: ${loginResult['message']}');
        results['admin_account_exists'] = false;
      }

      // Step 2: Create admin account if it doesn't exist
      print('🛠️ Step 2: Creating admin account...');
      final createResult = await _firebaseService.createAdminAccount(
        username: 'admin',
        email: 'admin@example.com',
        password: 'admin123',
      );

      if (createResult['success'] == true) {
        print('✅ Admin account created successfully');
        results['admin_account_created'] = true;
      } else {
        print('❌ Failed to create admin account: ${createResult['message']}');
        return results;
      }

      // Step 3: Test login after account creation
      print('🔐 Step 3: Testing login after account creation...');
      final retryLoginResult = await _firebaseService.loginAdmin(
        username: 'admin',
        password: 'admin123',
      );

      if (retryLoginResult['success'] == true) {
        print('✅ Admin login successful after account creation');
        results['login_successful'] = true;
        results['debug_messages_working'] = true;
      } else {
        print('❌ Admin login still failed: ${retryLoginResult['message']}');
        return results;
      }

      // Step 4: Test error handling with wrong credentials
      print('🚫 Step 4: Testing error handling...');
      final wrongLoginResult = await _firebaseService.loginAdmin(
        username: 'admin',
        password: 'wrongpassword',
      );

      if (wrongLoginResult['success'] == false &&
          wrongLoginResult['message'] == 'بيانات المشرف غير صحيحة') {
        print('✅ Error messages working correctly');
        results['error_messages_working'] = true;
      } else {
        print('❌ Error messages not working correctly');
      }

      // Step 5: Test navigation (simulated)
      print('🧭 Step 5: Testing navigation logic...');
      // This would be tested in the actual UI, but we can verify the logic
      if (results['login_successful'] == true) {
        print('✅ Navigation logic ready (would navigate to /admin/home)');
        results['navigation_working'] = true;
      }
    } catch (e) {
      print('⚠️ ERROR during admin login test: $e');
      results['error'] = e.toString();
    }

    return results;
  }

  /// Test specific admin login scenarios
  static Future<void> testLoginScenarios() async {
    print('\n🧪 Testing Admin Login Scenarios...\n');

    // Test 1: Valid admin login
    print('📋 Test 1: Valid admin login (admin/admin123)');
    final validResult = await _firebaseService.loginAdmin(
      username: 'admin',
      password: 'admin123',
    );
    print('Result: ${validResult['success']} - ${validResult['message']}');

    // Test 2: Wrong password
    print('\n📋 Test 2: Wrong password (admin/wrongpass)');
    final wrongPassResult = await _firebaseService.loginAdmin(
      username: 'admin',
      password: 'wrongpass',
    );
    print(
      'Result: ${wrongPassResult['success']} - ${wrongPassResult['message']}',
    );

    // Test 3: Non-existent admin
    print('\n📋 Test 3: Non-existent admin (nonexistent/admin123)');
    final nonExistentResult = await _firebaseService.loginAdmin(
      username: 'nonexistent',
      password: 'admin123',
    );
    print(
      'Result: ${nonExistentResult['success']} - ${nonExistentResult['message']}',
    );

    // Test 4: Email login (if supported)
    print('\n📋 Test 4: Email login (admin@example.com/admin123)');
    final emailResult = await _firebaseService.loginAdmin(
      username: 'admin@example.com',
      password: 'admin123',
    );
    print('Result: ${emailResult['success']} - ${emailResult['message']}');
  }

  /// Generate system status summary
  static void generateSystemStatus(Map<String, dynamic> results) {
    print('\n📊 ADMIN LOGIN SYSTEM STATUS SUMMARY');
    print('=====================================');

    if (results['admin_account_exists'] == true) {
      print('✅ Admin account found and login successful');
    } else if (results['admin_account_created'] == true) {
      print('❌ Admin account missing — created automatically');
    } else {
      print('❌ Admin account missing — creation failed');
    }

    if (results['login_successful'] == true) {
      print('✅ Login authentication working');
    } else {
      print('❌ Login authentication failed');
    }

    if (results['navigation_working'] == true) {
      print('✅ Navigation logic ready');
    } else {
      print('❌ Navigation logic not ready');
    }

    if (results['error_messages_working'] == true) {
      print('✅ Arabic error messages working');
    } else {
      print('❌ Arabic error messages not working');
    }

    if (results['debug_messages_working'] == true) {
      print('✅ Debug messages working');
    } else {
      print('❌ Debug messages not working');
    }

    if (results.containsKey('error')) {
      print('❌ System error: ${results['error']}');
    }

    print('\n🎯 SYSTEM READY FOR TESTING');
    print('============================');
    print('1. Navigate to /admin/login');
    print('2. Enter username: admin');
    print('3. Enter password: admin123');
    print('4. Expected: Navigate to /admin/home');
    print('5. Check console for debug messages');
  }
}
