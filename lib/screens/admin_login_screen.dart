import 'package:flutter/material.dart';
import 'package:new_project/database/firebase_service.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAccount({required bool isAdmin}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      print('🔍 Attempting admin login for: $username');

      // Use FirebaseService for admin login
      final result = await FirebaseService().loginAdmin(
        username: username,
        password: password,
      );

      print('📋 Login result: $result');

      if (result['success'] == true) {
        print('✅ Admin login successful');

        // Set admin session in AuthProvider
        final authProvider = context.read<AuthProvider>();
        authProvider.setAdminSession(username, {
          'name': result['admin']['name'] ?? username,
          'email': result['admin']['email'] ?? '$username@admin.com',
          'role': 'admin',
        });
        
        print('[AdminLogin] role=admin set → /admin/home');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin/home',
            (_) => false,
          );
        }
      } else {
        print('❌ Admin login failed: ${result['message']}');

        // If admin account doesn't exist, try to create one automatically
        if (result['message'] == 'بيانات المشرف غير صحيحة') {
          print('🔄 No admin account found, attempting to create one...');
          await _createDefaultAdminAccount();

          // Try login again after creating admin account
          final retryResult = await FirebaseService().loginAdmin(
            username: username,
            password: password,
          );

          if (retryResult['success'] == true) {
            print('✅ Admin login successful after account creation');

            // Set admin session in AuthProvider
            final authProvider = context.read<AuthProvider>();
            authProvider.setAdminSession(username, {
              'name': retryResult['admin']['name'] ?? username,
              'email': retryResult['admin']['email'] ?? '$username@admin.com',
              'role': 'admin',
            });
            
            print('[AdminLogin] role=admin set → /admin/home');
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/admin/home',
                (_) => false,
              );
            }
          } else {
            print('❌ Admin login still failed after account creation');
            _showError('بيانات المشرف غير صحيحة');
          }
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      print('⚠️ ERROR during admin login: $e');
      _showError('حدث خطأ أثناء تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultAdminAccount() async {
    try {
      print('🛠️ Creating default admin account...');
      final result = await FirebaseService().createAdminAccount(
        username: 'admin',
        email: 'admin@example.com',
        password: 'admin123',
      );

      if (result['success'] == true) {
        print('✅ Default admin account created successfully');
      } else {
        print('❌ Failed to create admin account: ${result['message']}');
      }
    } catch (e) {
      print('⚠️ ERROR creating admin account: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('تسجيل دخول المشرف'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'دخول المشرف',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    if (value.trim().length < 3) {
                      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _loginAccount(isAdmin: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'العودة إلى تسجيل الدخول',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
