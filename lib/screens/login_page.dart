import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/sheikh_auth_service.dart';
import 'package:new_project/utils/role_router.dart';

class LoginPage extends StatefulWidget {
  final Function(bool) toggleTheme;
  final VoidCallback? onLoginSuccess;
  const LoginPage({super.key, required this.toggleTheme, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User login controllers
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final _userFormKey = GlobalKey<FormState>();

  // Sheikh login controllers
  final TextEditingController _sheikhUniqueIdController =
      TextEditingController();
  final TextEditingController _sheikhPasswordController =
      TextEditingController();
  final _sheikhFormKey = GlobalKey<FormState>();

  bool _obscureUserPassword = true;
  bool _obscureSheikhPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Clear any previous error messages when the login page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _sheikhUniqueIdController.dispose();
    _sheikhPasswordController.dispose();
    super.dispose();
  }

  void _loginUser() async {
    if (_userFormKey.currentState?.validate() != true) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.loginUserWithEmail(
        _userEmailController.text.trim(),
        _userPasswordController.text,
      );

      // Success - navigate to home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Use callback if provided, otherwise use default navigation
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess?.call();
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // Error handled in provider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'حدث خطأ في تسجيل الدخول',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loginSheikh() async {
    if (_sheikhFormKey.currentState?.validate() != true) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final sheikhId = _sheikhUniqueIdController.text.trim();
      final password = _sheikhPasswordController.text.trim();

      // Validate input
      if (sheikhId.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إدخال رقم الشيخ وكلمة المرور'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate sheikhId format - enforce exactly 8 digits
      final normalized = sheikhId.replaceAll(RegExp(r'[^0-9]'), '');
      if (normalized.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الشيخ غير صحيح'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Enforce exactly 8 digits - no padding, must be exactly 8 digits
      if (normalized.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الشيخ يجب أن يكون 8 أرقام بالضبط'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Use SheikhAuthService for direct authentication
      final authService = SheikhAuthService();
      final result = await authService.authenticateSheikh(sheikhId, password);

      if (result['success'] == true && mounted) {
        final sheikhData = result['sheikh'] as Map<String, dynamic>;

        // Verify the user's role is set to 'sheikh'
        if (sheikhData['role'] != 'sheikh') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('هذا الحساب ليس حساب شيخ'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Verify the account is active
        if (sheikhData['isActive'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الحساب غير مفعّل'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Set the Sheikh session in AuthProvider
        authProvider.setSheikhSession({
          'uid': sheikhData['uid'],
          'name': sheikhData['name'],
          'email': sheikhData['email'],
          'sheikhId': sheikhData['uniqueId'],
          'category': sheikhData['category'],
        });

        // Success - show success message
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
        final message = result['message'] ?? 'رقم الشيخ أو كلمة المرور غير صحيحة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تسجيل الدخول'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('تسجيل الدخول'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin_login');
                },
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'دخول المشرف',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'دخول المستخدمين'),
              Tab(text: 'دخول الشيوخ'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // User Login Tab
                  _buildUserLoginTab(),
                  // Sheikh Login Tab
                  _buildSheikhLoginTab(),
                ],
              ),
            ),
            // Browse as Guest button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.enterGuestMode();
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'تصفح كضيف',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _userFormKey,
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
              child: const Icon(Icons.person, size: 50, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'دخول المستخدمين',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userPasswordController,
              obscureText: _obscureUserPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureUserPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _obscureUserPassword = !_obscureUserPassword,
                  ),
                ),
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
              },
            ),
            const SizedBox(height: 16),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/register');
                        },
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheikhLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _sheikhFormKey,
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
              child: const Icon(Icons.mosque, size: 50, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'دخول الشيوخ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _sheikhUniqueIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المعرف الفريد (8 أرقام)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال المعرف الفريد';
                }
                final normalized = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
                if (normalized.isEmpty) {
                  return 'رقم الشيخ غير صحيح';
                }
                if (normalized.length != 8) {
                  return 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sheikhPasswordController,
              obscureText: _obscureSheikhPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSheikhPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _obscureSheikhPassword = !_obscureSheikhPassword,
                  ),
                ),
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _loginSheikh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
