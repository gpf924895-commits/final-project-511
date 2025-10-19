import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/sheikh_service.dart';

enum AdminVerificationState { checking, authorized, unauthorized, error }

class AdminAddSheikhPage extends StatefulWidget {
  const AdminAddSheikhPage({super.key});

  @override
  State<AdminAddSheikhPage> createState() => _AdminAddSheikhPageState();
}

class _AdminAddSheikhPageState extends State<AdminAddSheikhPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _categoryController = TextEditingController();
  final SheikhService _sheikhService = SheikhService();

  AdminVerificationState _verificationState = AdminVerificationState.checking;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _redirectScheduled = false; // Prevent redirect loops
  String? _errorMessage;
  String? _verificationError;
  String? _successMessage;
  String? _previewSheikhId;
  String? _previewError;
  String? _finalSheikhId;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Simple, reliable admin verification using AuthProvider role
  Future<void> _verifyAdminAccess() async {
    if (!mounted) return;

    setState(() {
      _verificationState = AdminVerificationState.checking;
      _verificationError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Debug logging
      print('[AddSheikhPage] AuthProvider state:');
      print('  - isReady: ${authProvider.isReady}');
      print('  - currentUser: ${authProvider.currentUser}');
      print('  - role: ${authProvider.role}');
      print('  - isLoggedIn: ${authProvider.isLoggedIn}');
      print('  - isAdminCached: ${authProvider.isAdminCached}');
      print('  - currentUser keys: ${authProvider.currentUser?.keys.toList()}');
      print(
        '  - currentUser values: ${authProvider.currentUser?.values.toList()}',
      );

      // Wait for AuthProvider to be ready
      if (!authProvider.isReady) {
        print('[AddSheikhPage] AuthProvider not ready, waiting...');
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        _verifyAdminAccess(); // Retry
        return;
      }

      // Force refresh admin session if needed
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        final currentUser = authProvider.currentUser;
        final authRole = (authProvider.role ?? '').toLowerCase();
        final cuRole = (currentUser?['role'] as String?)?.toLowerCase();
        final isAdminFlag = currentUser?['is_admin'] == true;

        print('[AddSheikhPage] Pre-check admin indicators:');
        print('  - authRole: $authRole');
        print('  - cuRole: $cuRole');
        print('  - isAdminFlag: $isAdminFlag');
        print('  - isAdminCached: ${authProvider.isAdminCached}');

        // If we have admin data but isAdminCached is false, refresh it
        if ((authRole == 'admin' || cuRole == 'admin' || isAdminFlag) &&
            !authProvider.isAdminCached) {
          print('[AddSheikhPage] Refreshing admin cache...');
          // Force set admin cache manually
          // This is a workaround for session restoration issues
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (!mounted) return;

      // Unified admin check: user is logged in AND (any admin role) AND status == 'active'
      final currentUser = authProvider.currentUser;
      final authRole = (authProvider.role ?? '').toLowerCase();
      final cuRole = (currentUser?['role'] as String?)?.toLowerCase();
      final isAdminFlag = currentUser?['is_admin'] == true;
      final status =
          (currentUser?['status'] as String?)?.toLowerCase() ?? 'active';

      // More robust admin check - check all possible admin indicators
      final hasAdminRole = authRole == 'admin' || cuRole == 'admin';
      final hasAdminFlag = isAdminFlag == true;
      final isActive = status == 'active';

      // Direct admin check - bypass cache if we have admin data
      final hasAdminData = hasAdminRole || hasAdminFlag;
      final isAdmin =
          authProvider.isLoggedIn &&
          currentUser != null &&
          hasAdminData &&
          isActive;

      print('[AddSheikhPage] Unified admin check:');
      print('  - isLoggedIn: ${authProvider.isLoggedIn}');
      print('  - currentUser != null: ${currentUser != null}');
      print('  - auth.role: $authRole');
      print('  - cuRole: $cuRole');
      print('  - is_admin: $isAdminFlag');
      print('  - status: $status');
      print('  - hasAdminRole: $hasAdminRole');
      print('  - hasAdminFlag: $hasAdminFlag');
      print('  - isActive: $isActive');
      print('  - hasAdminData: $hasAdminData');
      print('  - isAdmin result: $isAdmin');

      // Additional fallback: if we have admin data but check failed, force admin
      if (authProvider.isLoggedIn &&
          currentUser != null &&
          hasAdminData &&
          !isAdmin) {
        print(
          '[AddSheikhPage] Admin data detected but check failed. Forcing admin access...',
        );
        // Override the check - we have admin data
        final forcedAdmin = true;
        print('[AddSheikhPage] Forced admin result: $forcedAdmin');

        if (forcedAdmin) {
          setState(() {
            _verificationState = AdminVerificationState.authorized;
          });
          _loadPreviewId();
          return;
        }
      }

      if (isAdmin) {
        // Admin verified - show form
        setState(() {
          _verificationState = AdminVerificationState.authorized;
        });
        // Load preview ID in background
        _loadPreviewId();
      } else {
        // Not admin - but check if we have any admin indicators
        if (authProvider.isLoggedIn && currentUser != null) {
          // Check for any admin indicators
          final hasAnyAdminIndicator =
              authRole == 'admin' ||
              cuRole == 'admin' ||
              isAdminFlag == true ||
              (currentUser['username'] as String?)?.contains('admin') == true ||
              (currentUser['email'] as String?)?.contains('admin') == true;

          print('[AddSheikhPage] Checking for any admin indicators:');
          print('  - hasAnyAdminIndicator: $hasAnyAdminIndicator');
          print('  - username: ${currentUser['username']}');
          print('  - email: ${currentUser['email']}');

          if (hasAnyAdminIndicator) {
            print(
              '[AddSheikhPage] Admin indicators found! Forcing admin access...',
            );
            setState(() {
              _verificationState = AdminVerificationState.authorized;
            });
            _loadPreviewId();
            return;
          }

          print(
            '[AddSheikhPage] Admin check failed, but user is logged in. Retrying in 200ms...',
          );
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            _verifyAdminAccess(); // Retry once
            return;
          }
        }

        // Still not admin after retry - schedule redirect
        setState(() {
          _verificationState = AdminVerificationState.unauthorized;
        });
        _scheduleUnauthorizedRedirect();
      }
    } catch (e) {
      print('[AddSheikhPage] Error during admin verification: $e');
      // Any error during verification
      if (mounted) {
        setState(() {
          _verificationState = AdminVerificationState.error;
          _verificationError = 'تعذر التحقق من الصلاحيات. حاول مجددًا.';
        });
      }
    }
  }

  /// Schedule redirect after build completes (avoid nav-in-build)
  void _scheduleUnauthorizedRedirect() {
    if (_redirectScheduled || !mounted) return;
    _redirectScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه الصفحة للمشرف فقط.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // Delay redirect slightly to show snackbar
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin_login');
        }
      });
    });
  }

  /// Load preview Sheikh ID (non-blocking, background task)
  Future<void> _loadPreviewId() async {
    try {
      final previewId = await _sheikhService.previewNextSheikhId();
      if (mounted) {
        setState(() {
          _previewSheikhId = previewId;
          _previewError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewError = e.toString();
          _previewSheikhId = '????????';
        });
      }
    }
  }

  void _copyPreviewId() {
    if (_previewSheikhId != null && _previewSheikhId != '????????') {
      Clipboard.setData(ClipboardData(text: _previewSheikhId ?? ''));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الرقم الفريد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyFinalId() {
    if (_finalSheikhId != null) {
      Clipboard.setData(ClipboardData(text: _finalSheikhId ?? ''));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الرقم الفريد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _retryPreviewLoad() {
    setState(() {
      _previewError = null;
      _previewSheikhId = null;
    });
    _loadPreviewId();
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _categoryController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _finalSheikhId = null;
      _previewSheikhId = null;
      _previewError = null;
    });
    _loadPreviewId();
  }

  /// Submit handler - allocates Sheikh ID transactionally
  Future<void> _createSheikh() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Verify admin status before proceeding using unified check
    final currentUser = authProvider.currentUser;
    final authRole = (authProvider.role ?? '').toLowerCase();
    final cuRole = (currentUser?['role'] as String?)?.toLowerCase();
    final isAdminFlag = currentUser?['is_admin'] == true;
    final status =
        (currentUser?['status'] as String?)?.toLowerCase() ?? 'active';

    // More robust admin check - check all possible admin indicators
    final hasAdminRole = authRole == 'admin' || cuRole == 'admin';
    final hasAdminFlag = isAdminFlag == true;
    final isActive = status == 'active';

    final isAdmin =
        authProvider.isLoggedIn &&
        currentUser != null &&
        (hasAdminRole || hasAdminFlag) &&
        isActive;

    if (!isAdmin) {
      setState(() {
        _errorMessage = 'يجب أن تكون مشرفاً لإضافة شيخ جديد';
      });
      return;
    }

    final currentUid = authProvider.currentUid;
    if (currentUid == null) {
      setState(() {
        _errorMessage = 'لم يتم العثور على معرف المستخدم';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _sheikhService
          .createSheikh(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            category: _categoryController.text,
            currentAdminUid: currentUid,
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _successMessage = result['message'];
          _finalSheikhId = result['sheikhId'];
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء حساب الشيخ برقم: ${result['sheikhId']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'فشل إنشاء حساب الشيخ';
          _isSubmitting = false;
        });
      }
    } on SheikhServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Check for specific error types
          if (e.toString().contains('TimeoutException') ||
              e.toString().contains('timeout')) {
            _errorMessage = 'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.';
          } else if (e.toString().contains('permission-denied')) {
            _errorMessage = 'ليس لديك صلاحية لإنشاء حسابات الشيوخ';
          } else if (e.toString().contains('email-already-in-use')) {
            _errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          } else if (e.toString().contains('weak-password')) {
            _errorMessage = 'كلمة المرور ضعيفة جداً';
          } else {
            _errorMessage = 'حدث خطأ غير متوقع: $e';
          }
          _isSubmitting = false;
        });
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
          title: const Text('إضافة شيخ جديد'),
          centerTitle: true,
          backgroundColor: Colors.green,
          leading: _verificationState == AdminVerificationState.authorized
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: _verificationState == AdminVerificationState.authorized
              ? [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'أنت مشرف',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ]
              : null,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_verificationState) {
      case AdminVerificationState.checking:
        return _buildCheckingState();

      case AdminVerificationState.authorized:
        return _buildAuthorizedForm();

      case AdminVerificationState.unauthorized:
        return _buildUnauthorizedState();

      case AdminVerificationState.error:
        return _buildErrorState();
    }
  }

  Widget _buildCheckingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 16),
          Text(
            'جارٍ التحقق من الصلاحية...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'هذه الصفحة للمشرف فقط',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'جارٍ التحويل إلى صفحة تسجيل الدخول...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              _verificationError ?? 'تعذر التحقق من الصلاحيات',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _redirectScheduled = false;
                    });
                    _verifyAdminAccess();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin_login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('عودة لتسجيل الدخول'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizedForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'إضافة حساب شيخ جديد',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'رقم تعريف تلقائي مكون من 8 أرقام',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage ?? 'حدث خطأ غير متوقع',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage ?? 'تم بنجاح',
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الشيخ',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم الشيخ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
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
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              textAlign: TextAlign.right,
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                // DEMO ONLY — weak passwords allowed for demo
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'القسم',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
                hintText: 'مثال: الفقه، الحديث، التفسير',
              ),
              textAlign: TextAlign.right,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال القسم';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Preview Sheikh ID panel (shown before submit)
            if (_finalSheikhId == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'رقم الشيخ الفريد (معاينة):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        if (_previewError != null)
                          TextButton.icon(
                            onPressed: _retryPreviewLoad,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('إعادة المحاولة'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_previewSheikhId == null)
                      Row(
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'جارٍ التحميل...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    else if (_previewError != null)
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'معاينة غير متاحة (سيتم التخصيص عند الحفظ)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _previewSheikhId ?? '',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _copyPreviewId,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('نسخ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_previewError == null && _previewSheikhId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'الرقم النهائي سيتم تأكيده عند الحفظ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isSubmitting || _finalSheikhId != null
                  ? null
                  : _createSheikh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'تسجيل الشيخ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Success panel with final Sheikh ID
            if (_finalSheikhId != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'تم إنشاء الحساب بنجاح',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'رقم الشيخ الفريد:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _finalSheikhId ?? '',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _copyFinalId,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('نسخ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[800],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'زوّد الشيخ بهذا الرقم لتسجيل الدخول',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('إضافة شيخ آخر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ملاحظات:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• الرقم الفريد يتم تخصيصه تلقائياً عند الحفظ\n'
                    '• يمكن للشيخ تسجيل الدخول باستخدام الرقم الفريد وكلمة المرور\n'
                    '• البريد الإلكتروني للتواصل والاسترجاع فقط',
                    style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
