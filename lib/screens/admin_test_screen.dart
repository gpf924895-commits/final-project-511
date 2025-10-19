import 'package:flutter/material.dart';
import 'package:new_project/utils/admin_test_helper.dart';
import 'package:new_project/utils/admin_login_test.dart';

/// Test screen to help verify admin authentication pipeline
/// This screen should only be used for development/testing
class AdminTestScreen extends StatefulWidget {
  const AdminTestScreen({super.key});

  @override
  State<AdminTestScreen> createState() => _AdminTestScreenState();
}

class _AdminTestScreenState extends State<AdminTestScreen> {
  bool _isLoading = false;
  String _status = '';

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _status = message;
      });
    }
  }

  Future<void> _createTestAdmins() async {
    _setLoading(true);
    _updateStatus('Creating test admin accounts...');

    try {
      await AdminTestHelper.createTestAdmins();
      _updateStatus('✅ Test admin accounts created successfully!');
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createTestUsers() async {
    _setLoading(true);
    _updateStatus('Creating test user accounts...');

    try {
      await AdminTestHelper.createTestUsers();
      _updateStatus('✅ Test user accounts created successfully!');
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createAllTestAccounts() async {
    _setLoading(true);
    _updateStatus('Creating all test accounts...');

    try {
      await AdminTestHelper.createAllTestAccounts();
      _updateStatus(
        '✅ All test accounts (admins + users) created successfully!',
      );
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _verifyAdmin() async {
    _setLoading(true);
    _updateStatus('Verifying admin account...');

    try {
      final exists = await AdminTestHelper.verifyAdminExists('admin');
      _updateStatus(
        exists ? '✅ Admin account exists' : '❌ Admin account not found',
      );
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testAdminLoginSystem() async {
    _setLoading(true);
    _updateStatus('Testing complete admin login system...');

    try {
      final results = await AdminLoginTest.testAdminLoginSystem();
      AdminLoginTest.generateSystemStatus(results);

      // Update status with summary
      final status = results['login_successful'] == true
          ? '✅ Admin login system working correctly'
          : '❌ Admin login system has issues';
      _updateStatus(status);
    } catch (e) {
      _updateStatus('❌ Error testing admin login system: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testLoginScenarios() async {
    _setLoading(true);
    _updateStatus('Testing admin login scenarios...');

    try {
      await AdminLoginTest.testLoginScenarios();
      _updateStatus('✅ Login scenarios tested - check console for details');
    } catch (e) {
      _updateStatus('❌ Error testing login scenarios: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _listAdmins() async {
    _setLoading(true);
    _updateStatus('Listing admin accounts...');

    try {
      await AdminTestHelper.listAdmins();
      _updateStatus('✅ Admin accounts listed (check console)');
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('اختبار إدارة المشرفين'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أدوات اختبار إدارة المشرفين',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Create test admins button
              ElevatedButton(
                onPressed: _isLoading ? null : _createTestAdmins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إنشاء حسابات مشرفين تجريبية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Create test users button
              ElevatedButton(
                onPressed: _isLoading ? null : _createTestUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'إنشاء حسابات مستخدمين تجريبية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Create all test accounts button
              ElevatedButton(
                onPressed: _isLoading ? null : _createAllTestAccounts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'إنشاء جميع الحسابات التجريبية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Verify admin button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'التحقق من وجود حساب المشرف',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // List admins button
              ElevatedButton(
                onPressed: _isLoading ? null : _listAdmins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'عرض جميع حسابات المشرفين',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Test admin login system button
              ElevatedButton(
                onPressed: _isLoading ? null : _testAdminLoginSystem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'اختبار نظام تسجيل الدخول الكامل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Test login scenarios button
              ElevatedButton(
                onPressed: _isLoading ? null : _testLoginScenarios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'اختبار سيناريوهات تسجيل الدخول',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Status display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة العملية:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status.isEmpty ? 'لم يتم تنفيذ أي عملية بعد' : _status,
                      style: TextStyle(
                        fontSize: 14,
                        color: _status.contains('✅')
                            ? Colors.green
                            : _status.contains('❌')
                            ? Colors.red
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعليمات الاختبار:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. اضغط على "إنشاء جميع الحسابات التجريبية" لإنشاء بيانات الاختبار\n'
                      '2. اضغط على "التحقق من وجود حساب المشرف" للتأكد من البيانات\n'
                      '3. اختبر تسجيل الدخول:\n'
                      '   - للمشرفين: admin/admin123 أو supervisor/super123\n'
                      '   - للمستخدمين: user1/user123 أو user2/user456\n'
                      '4. تأكد من رسائل الخطأ العربية الصحيحة',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
