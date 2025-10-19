import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart' as auth_provider;
import 'package:new_project/screens/home_page.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class LoginTabbedScreen extends StatefulWidget {
  const LoginTabbedScreen({super.key});

  @override
  State<LoginTabbedScreen> createState() => _LoginTabbedScreenState();
}

class _LoginTabbedScreenState extends State<LoginTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sheikhCodeController = TextEditingController();
  final _sheikhPasswordController = TextEditingController();
  final _userFormKey = GlobalKey<FormState>();
  final _sheikhFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureSheikhPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sheikhCodeController.dispose();
    _sheikhPasswordController.dispose();
    super.dispose();
  }

  // Timeout wrapper for network calls
  Future<T> _withTimeout<T>(Future<T> future, {int seconds = 12}) {
    return future.timeout(
      Duration(seconds: seconds),
      onTimeout: () => throw TimeoutException('انتهت المهلة، تحقق من الاتصال.'),
    );
  }

  // Set loading state safely
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_userFormKey.currentState?.validate() != true) return;
    if (_isLoading) return; // Prevent multiple calls

    _setLoading(true);

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(
        context,
        listen: false,
      );

      final role = await _withTimeout(
        authProvider.loginUserOrSheikh(
          _emailController.text.trim(),
          _passwordController.text,
        ),
      );

      if (role != null && mounted) {
        _onLoginSuccess(context, role);
      } else if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'فشل في تسجيل الدخول');
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message ?? 'انتهت المهلة، تحقق من الاتصال.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(_getFirebaseErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('حدث خطأ غير متوقع: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleSheikhLogin() async {
    if (_sheikhFormKey.currentState?.validate() != true) return;
    if (_isLoading) return; // Prevent multiple calls

    _setLoading(true);

    try {
      final rawCode = _sheikhCodeController.text.trim();
      final secret = _sheikhPasswordController.text.trim();

      // Normalize code: pad to 8 digits with leading zeros
      final code = rawCode.padLeft(8, '0');

      print('[SheikhLogin] Raw code: $rawCode, Padded code: $code');

      // Get auth provider
      final authProvider = Provider.of<auth_provider.AuthProvider>(
        context,
        listen: false,
      );

      // Use the dedicated sheikh login method
      final success = await _withTimeout(
        authProvider.loginSheikhWithUniqueId(code, secret),
      );

      if (success && mounted) {
        print('[SheikhLogin] Success! Navigating to /sheikh/home');
        _onLoginSuccess(context, 'sheikh');
        return;
      } else if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'فشل في تسجيل الدخول');
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message ?? 'انتهت المهلة، تحقق من الاتصال.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(_getFirebaseErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('حدث خطأ غير متوقع: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Single method for all login success navigation
  void _onLoginSuccess(BuildContext context, String? role) {
    print('DEBUG: Login success with role: $role');
    switch (role) {
      case 'sheikh':
        print('DEBUG: Navigating to /sheikh/home');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/sheikh/home',
          (route) => false,
        );
        break;
      case 'admin':
        print('DEBUG: Navigating to /admin/home');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/home',
          (route) => false,
        );
        break;
      case 'supervisor':
        print('DEBUG: Navigating to /supervisor/home');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/supervisor/home',
          (route) => false,
        );
        break;
      case 'user':
      default:
        print('DEBUG: Navigating to /main (user or fallback)');
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        break;
    }
  }

  void _goToGuestHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage(toggleTheme: (isDark) {})),
      (route) => false,
    );
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Get Arabic error message for Firebase exceptions
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى لاحقاً';
      case 'network-request-failed':
        return 'تحقق من الاتصال بالإنترنت';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      default:
        return 'خطأ في تسجيل الدخول: ${e.message}';
    }
  }

  // Build User Login Form
  Widget _buildUserLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _userFormKey,
        child: Column(
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'البريد غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور قصيرة';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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

            // Guest Browse Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _goToGuestHome,
                child: const Text('تصفح كضيف', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),

            // Register Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _goToRegister,
                child: const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Sheikh Login Form
  Widget _buildSheikhLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _sheikhFormKey,
        child: Column(
          children: [
            // Unique Code Field
            TextFormField(
              controller: _sheikhCodeController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'الرقم الفريد',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
                hintText: '12345678',
                helperText:
                    'يجب إدخال 8 أرقام بالضبط',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الرقم الفريد';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'الرقم الفريد يجب أن يحتوي على أرقام فقط';
                }
                if (value.length != 8) {
                  return 'الرقم الفريد يجب أن يكون 8 أرقام بالضبط';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Secret Password Field
            TextFormField(
              controller: _sheikhPasswordController,
              obscureText: _obscureSheikhPassword,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'الرقم السري',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSheikhPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureSheikhPassword = !_obscureSheikhPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الرقم السري';
                }
                if (value.length < 6) {
                  return 'الرقم السري قصير';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSheikhLogin,
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

            // Guest Browse Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _goToGuestHome,
                child: const Text('تصفح كضيف', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E5D3),
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: () {
              // Navigate to admin login screen
              Navigator.pushNamed(context, '/admin/login');
            },
            tooltip: 'تسجيل دخول المشرف',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'المستخدمون'),
            Tab(icon: Icon(Icons.mosque), text: 'الشيوخ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          _buildUserLoginForm(),
          // Sheikh Tab
          _buildSheikhLoginForm(),
        ],
      ),
    );
  }
}
