import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/sheikh_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SheikhLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const SheikhLoginPage({super.key, this.onLoginSuccess});

  @override
  State<SheikhLoginPage> createState() => _SheikhLoginPageState();
}

class _SheikhLoginPageState extends State<SheikhLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _sheikhIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _sheikhIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final sheikhId = _sheikhIdController.text.trim();
    final password = _passwordController.text.trim();

    // Validate input
    if (sheikhId.isEmpty || password.isEmpty) {
      setState(() => _isLoading = false);
      _showErrorDialog('الرجاء إدخال رقم الشيخ وكلمة المرور');
      return;
    }

    // Validate sheikhId format - enforce exactly 8 digits
    final normalized = sheikhId.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      setState(() => _isLoading = false);
      _showErrorDialog('رقم الشيخ غير صحيح');
      return;
    }
    
    // Enforce exactly 8 digits - no padding, must be exactly 8 digits
    if (normalized.length != 8) {
      setState(() => _isLoading = false);
      _showErrorDialog('رقم الشيخ يجب أن يكون 8 أرقام بالضبط');
      return;
    }

    try {
      final authService = SheikhAuthService();

      // Use direct authentication method (no Firebase Auth required)
      final result = await authService.authenticateSheikh(sheikhId, password);

      setState(() => _isLoading = false);

      if (result['success'] == true && mounted) {
        final sheikhData = result['sheikh'] as Map<String, dynamic>;

        // Verify the user's role is set to 'sheikh'
        if (sheikhData['role'] != 'sheikh') {
          _showErrorDialog('هذا الحساب ليس حساب شيخ');
          return;
        }

        // Verify the account is active
        if (sheikhData['isActive'] != true) {
          _showErrorDialog('الحساب غير مفعّل');
          return;
        }

        // Update AuthProvider with the authenticated user data
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Set the Sheikh session in AuthProvider
        authProvider.setSheikhSession({
          'uid': sheikhData['uid'],
          'name': sheikhData['name'],
          'email': sheikhData['email'],
          'sheikhId': sheikhData['uniqueId'],
          'category': sheikhData['category'],
        });

        // Save Sheikh credentials to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sheikhId', sheikhData['uniqueId']);
        await prefs.setString('sheikhEmail', sheikhData['email']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'تم تسجيل الدخول بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Use callback if provided, otherwise use default navigation
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess?.call();
        } else {
          // Navigate directly to Sheikh home page
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sheikh/home',
            (route) => false,
          );
        }
      } else if (mounted) {
        final message =
            result['message'] ?? 'رقم الشيخ أو كلمة المرور غير صحيحة';
        _showErrorDialog(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خطأ في تسجيل الدخول'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('دخول الشيوخ'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'دخول الشيوخ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل معرف الشيخ وكلمة المرور',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _sheikhIdController,
                      decoration: InputDecoration(
                        labelText: 'معرف الشيخ (8 أرقام)',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال معرف الشيخ';
                        }
                        if (value.trim().length != 8) {
                          return 'معرف الشيخ يجب أن يكون 8 أرقام';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                      textAlign: TextAlign.right,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'دخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
