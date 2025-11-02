import 'package:flutter/material.dart';
import 'package:new_project/repository/local_repository.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/services/sheikh_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final LocalRepository _repository = LocalRepository();
  final SubcategoryService _subcategoryService = SubcategoryService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isGuest = true; // Start in guest mode by default
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;
  bool _isReady = false; // AuthProvider initialization status

  // Admin caching with TTL
  bool? _isAdminCached; // null = unknown, true/false = cached
  DateTime? _adminCheckedAt;
  static const Duration _adminCacheTTL = Duration(minutes: 5);
  bool _claimsRefreshed = false; // Track if claims were refreshed this session

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  // Removed duplicate - using RBAC version below
  bool get isAuthenticated =>
      _isLoggedIn && !_isGuest; // True only if logged in and not guest
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get currentUid => _currentUser?['uid'];
  String? get role => _currentUser?['role'];
  String? get currentRole =>
      _currentUser?['role']; // Keep for backward compatibility
  bool get isReady => _isReady; // AuthProvider initialization status

  // Safe getters
  String get displayName =>
      _currentUser?['name'] ??
      _currentUser?['username'] ??
      _currentUser?['email'] ??
      'زائر';

  bool get isSignedIn => _currentUser != null && _isLoggedIn;

  // RBAC (Role-Based Access Control) flags
  bool get isGuest => _currentUser == null;
  bool get isUser => _currentUser != null && (_currentUser?['role'] == 'user');
  bool get isSheikh => _currentUser?['role'] == 'sheikh';
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isSupervisor => _currentUser?['role'] == 'supervisor';

  // Combined permission checks
  bool get canInteract => isUser || isSheikh || isAdmin || isSupervisor;
  bool get canManage => isSheikh || isAdmin || isSupervisor;

  // Admin getters with cache
  bool get isAdminCached => _isAdminCached ?? false;
  bool get needsAdminRecheck {
    if (_adminCheckedAt == null || _isAdminCached == null) return true;
    return DateTime.now().difference(_adminCheckedAt ?? DateTime.now()) >
        _adminCacheTTL;
  }

  // Initialize AuthProvider
  Future<void> initialize() async {
    try {
      // Defer loading state change to avoid setState during build
      Future.microtask(() {
        _setLoading(true);
      });
      _setError(null);
      _isReady = false;

      // First, try to load session from SharedPreferences
      await _loadSessionFromPrefs();

      // If we have a session from SharedPreferences, use it
      if (_currentUser != null && _isLoggedIn) {
        print('[AuthProvider] Session restored from SharedPreferences');
        _isReady = true;
        _setLoading(false);
        notifyListeners();
        return;
      }

      // For offline-only: just restore session from SharedPreferences
      // No Firebase Auth to check - session is restored above if it exists
      // If no session found, remain in guest mode
      _currentUser = null;
      _isLoggedIn = false;
      _isGuest = true;
    } catch (e) {
      // Handle errors during initialization
      debugPrint('Auth initialization error: $e');
      _currentUser = null;
      _isLoggedIn = false;
      _isGuest = true;
      _setError('خطأ في تحميل بيانات المستخدم');
    } finally {
      _isReady = true;
      _setLoading(false);
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    _isLoading = false; // Also reset loading state
    notifyListeners();
  }

  // Reset authentication state (useful when returning to login page)
  void resetAuthState() {
    _errorMessage = null;
    _isLoading = false;
    // Keep _isLoggedIn and _currentUser as they are
    notifyListeners();
  }

  // User login
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _repository.loginUser(
        email: email.trim(),
        password: password,
      );

      if (result['success']) {
        // Get user data from LocalRepository
        final userData = result['user'] as Map<String, dynamic>;
        final userId = userData['id'] as String;
        final userProfile = await _repository.getUserProfile(userId);

        if (userProfile != null) {
          _currentUser = {
            'uid': userId,
            'id': userId,
            'name': userProfile['name'],
            'username': userProfile['username'],
            'email': userProfile['email'],
            'role': (userProfile['is_admin'] == true) ? 'admin' : 'user',
          };
          _isLoggedIn = true;
          _isGuest = false;
          _errorMessage = null;
          _isLoading = false;
          _isReady = true;

          // Save session to SharedPreferences
          await _saveSessionToPrefs();
          notifyListeners();
          return true;
        } else {
          _setError('بيانات المستخدم غير موجودة');
          return false;
        }
      } else {
        _isLoggedIn = false;
        _isGuest = true; // Return to guest mode
        _currentUser = null;
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _isGuest = true; // Return to guest mode
      _currentUser = null;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // User signup
  Future<bool> signupUser({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.registerUser(
        username: username.trim(),
        email: email.trim(),
        password: password,
      );

      _setLoading(false);

      if (result['success']) {
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ غير متوقع: $e');
      return false;
    }
  }

  // Admin login using database authentication
  Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _repository.loginAdmin(
        username: username.trim(),
        password: password,
      );

      if (result['success']) {
        _isLoggedIn = true;
        _isGuest = false; // Exit guest mode

        // Map 'id' to 'uid' and ensure is_admin is set
        final adminData = result['admin'] as Map<String, dynamic>;
        _currentUser = {
          'uid': adminData['id'], // Map id -> uid
          'username': adminData['username'],
          'email': adminData['email'],
          'is_admin': true,
          'role': 'admin', // Add role field for consistency
        };

        // Cache admin status immediately (no Firebase Auth needed for DB-based admin)
        _isAdminCached = true;
        _adminCheckedAt = DateTime.now();

        _errorMessage = null;
        _isLoading = false;
        _isReady = true;
        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        _isGuest = true; // Return to guest mode
        _currentUser = null;
        _errorMessage = result['message'];
        _isLoading = false;
        _isReady = true;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _isGuest = true; // Return to guest mode
      _currentUser = null;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh admin claims (called once after Firebase Auth login)
  Future<void> _refreshAdminClaims() async {
    if (_claimsRefreshed) return; // Only refresh once per session

    try {
      // Offline-only: no Firebase Auth
      final currentUser = null;
      if (currentUser != null) {
        // Force token refresh to get latest claims
        await currentUser.getIdTokenResult(true);
        _claimsRefreshed = true;
      }
    } catch (e) {
      // Silently fail - we'll rely on Firestore read
      debugPrint('Failed to refresh claims: $e');
    }
  }

  // Check if user is admin (legacy getter for backward compatibility)
  // Removed duplicate - using RBAC version above

  // ==================== ADMIN GUARD UTILITY ====================

  /// Ensure current user is admin with caching and timeout
  /// Returns true if admin, false otherwise
  /// Does NOT navigate - caller must handle navigation
  Future<bool> ensureAdmin({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // Fast path: if cached and not expired, return immediately
      if (_isAdminCached != null && !needsAdminRecheck) {
        return _isAdminCached ?? false;
      }

      // Check current user from state first (handles DB-based admin login)
      if (_currentUser != null &&
          (_currentUser?['is_admin'] as bool?) == true) {
        _isAdminCached = true;
        _adminCheckedAt = DateTime.now();
        notifyListeners();
        return true;
      }

      // Check Firebase Auth user (for Firebase Auth-based logins)
      // Offline-only: no Firebase Auth
      final currentAuthUser = null;
      if (currentAuthUser == null) {
        _isAdminCached = false;
        _adminCheckedAt = DateTime.now();
        notifyListeners();
        return false;
      }

      // Refresh claims once if not done yet
      if (!_claimsRefreshed) {
        await _refreshAdminClaims();
      }

      // For offline-only: check from current user state
      if (_currentUser != null) {
        final isAdminUser = (_currentUser?['is_admin'] as bool?) == true;
        _isAdminCached = isAdminUser;
        _adminCheckedAt = DateTime.now();
        notifyListeners();
        return isAdminUser;
      }

      // No current user means not admin
      _isAdminCached = false;
      _adminCheckedAt = DateTime.now();
      notifyListeners();
      return false;
    } on TimeoutException {
      // On timeout, return false but don't cache (allow retry)
      debugPrint('Admin check timed out');
      return false;
    } catch (e) {
      // On error, return false but don't cache (allow retry)
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Reset admin cache
  void _resetAdminCache() {
    _isAdminCached = null;
    _adminCheckedAt = null;
    _claimsRefreshed = false;
  }

  // ==================== GUEST MODE ====================

  // Enter guest mode (browse without authentication)
  void enterGuestMode() {
    _isGuest = true;
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    _resetAdminCache();
    _isReady = true; // Keep ready after logout
    notifyListeners();
  }

  // Exit guest mode and return to guest (used after logout)
  void signOutToGuest() {
    _resetAdminCache();
    enterGuestMode();
  }

  // ==================== NEW FIREBASE AUTH METHODS ====================

  // DEMO ONLY — Weak passwords allowed (not for production)
  // Register new user with Firebase Auth
  Future<void> registerUser(String name, String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // Create user with Firebase Auth
      // Use LocalRepository instead of Firebase Auth
      final result = await _repository.registerUser(
        username: name.trim(),
        email: email.trim(),
        password: password,
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'فشل التسجيل');
      }

      final userId = result['user_id'] as String;

      // User already created by LocalRepository.registerUser()
      // Just get the profile
      final userProfile = await _repository.getUserProfile(userId);

      if (userProfile == null) {
        throw Exception('فشل في الحصول على بيانات المستخدم');
      }

      // Auto-login after registration
      _isLoggedIn = true;
      _isGuest = false; // Exit guest mode
      _currentUser = {
        'uid': userId,
        'id': userId,
        'name': userProfile['name'] ?? name.trim(),
        'username': userProfile['username'],
        'email': userProfile['email'] ?? email.trim(),
        'role': (userProfile['is_admin'] == true) ? 'admin' : 'user',
      };

      // Save session
      await _saveSessionToPrefs();

      _errorMessage = null;
      _isLoading = false;
      _isReady = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      notifyListeners();
    }
  }

  // Login with email/password (for regular users)
  Future<void> loginUserWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // Use LocalRepository for login
      final result = await _repository.loginUser(
        email: email.trim(),
        password: password,
      );

      if (!result['success']) {
        _errorMessage = result['message'] ?? 'فشل تسجيل الدخول';
        _isLoading = false;
        _isLoggedIn = false;
        _currentUser = null;
        notifyListeners();
        return;
      }

      // Get user profile
      final userData = result['user'] as Map<String, dynamic>;
      final userId = userData['id'] as String;
      final userProfile = await _repository.getUserProfile(userId);

      if (userProfile == null) {
        _errorMessage = 'بيانات المستخدم غير موجودة';
        _isLoading = false;
        _isLoggedIn = false;
        _currentUser = null;
        notifyListeners();
        return;
      }

      final isAdmin = userProfile['is_admin'] == true;
      final role = isAdmin ? 'admin' : 'user';

      // Only allow 'user' role for this login method
      if (role != 'user') {
        // Clear session
        if (role == 'sheikh') {
          _errorMessage = 'هذا الحساب خاص بالشيوخ. الرجاء الدخول برقم الشيخ';
        } else {
          _errorMessage = 'يرجى استخدام تسجيل دخول الشيوخ';
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Set user session
      _isLoggedIn = true;
      _isGuest = false; // Exit guest mode
      _currentUser = {
        'uid': userId,
        'id': userId,
        'name': userProfile['name'],
        'username': userProfile['username'],
        'email': userProfile['email'],
        'role': role,
      };

      // Save session
      await _saveSessionToPrefs();

      _errorMessage = null;
      _isLoading = false;
      _isReady = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      notifyListeners();
    }
  }

  // Sheikh login using uniqueId + password only (no Firebase Auth)
  Future<bool> loginSheikhWithUniqueId(String uniqueId, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // Import SheikhAuthService
      final sheikhAuthService = SheikhAuthService();

      // Use the service to authenticate
      final result = await sheikhAuthService.authenticateSheikh(
        uniqueId,
        password,
      );

      if (result['success'] == true) {
        final sheikhData = result['sheikh'] as Map<String, dynamic>;

        // Set Sheikh session without Firebase Auth
        _currentUser = {
          'uid': sheikhData['uid'],
          'name': sheikhData['name'],
          'email': sheikhData['email'],
          'role': 'sheikh',
          'sheikhId': sheikhData['uniqueId'],
          'category': sheikhData['category'],
          'isActive': sheikhData['isActive'],
        };

        _isLoggedIn = true;
        _isGuest = false;
        _errorMessage = null;
        _isLoading = false;
        _isReady = true;

        // Save session to SharedPreferences
        await _saveSessionToPrefs();

        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        _isGuest = true;
        _currentUser = null;
        _errorMessage =
            result['message'] ?? 'رقم الشيخ أو كلمة المرور غير صحيحة';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isLoggedIn = false;
      _isGuest = true;
      _currentUser = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Sign out from Firebase Auth and return to guest mode
  Future<void> logout() async {
    _resetAdminCache();
    _currentUser = null;
    _isLoggedIn = false;
    _isGuest = true;
    _errorMessage = null;
    _isReady = false; // Set ready to false after logout

    // Clear SharedPreferences session
    await _clearSessionFromPrefs();
    notifyListeners();

    // Set isReady back to true after clearing session
    Future.delayed(const Duration(milliseconds: 100), () {
      _isReady = true;
      notifyListeners();
    });
  }

  // Clear session from SharedPreferences
  Future<void> _clearSessionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('is_admin');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('is_logged_in');
      await prefs.remove('sheikh_id');
      await prefs.remove('sheikh_uid');
      print('[AuthProvider] Session cleared from SharedPreferences');
    } catch (e) {
      print('[AuthProvider] Error clearing session: $e');
    }
  }

  // Keep signOut for backward compatibility
  Future<void> signOut() async {
    await logout();
  }

  // Set admin session (for admin login screen)
  void setAdminSession(String username, Map<String, dynamic> adminData) {
    _currentUser = {
      'uid': 'admin_$username',
      'name': adminData['name'] ?? username,
      'email': adminData['email'] ?? '$username@admin.com',
      'role': 'admin',
      'username': username,
      'is_admin': true,
      'status': 'active', // Add status field
    };
    _isLoggedIn = true;
    _isGuest = false;
    _errorMessage = null;

    // Set admin cache to true for immediate access
    _isAdminCached = true;
    _adminCheckedAt = DateTime.now();

    // Persist session to SharedPreferences
    _saveSessionToPrefs();
    notifyListeners();
  }

  // Set Sheikh session (for Sheikh login)
  void setSheikhSession(Map<String, dynamic> sheikhData) {
    _currentUser = {
      'uid': sheikhData['uid'],
      'name': sheikhData['name'],
      'email': sheikhData['email'],
      'role': 'sheikh',
      'sheikhId': sheikhData['sheikhId'],
      'category': sheikhData['category'],
      'is_admin': false,
      'status': 'active',
    };
    _isLoggedIn = true;
    _isGuest = false;
    _errorMessage = null;

    // Persist session to SharedPreferences
    _saveSessionToPrefs();
    notifyListeners();
  }

  // Save session to SharedPreferences
  Future<void> _saveSessionToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString('user_role', _currentUser!['role'] ?? '');
        await prefs.setBool('is_admin', _currentUser!['is_admin'] ?? false);
        await prefs.setString('username', _currentUser!['username'] ?? '');
        await prefs.setString('email', _currentUser!['email'] ?? '');
        await prefs.setBool('is_logged_in', _isLoggedIn);

        // Save Sheikh-specific data
        if (_currentUser!['role'] == 'sheikh') {
          await prefs.setString('sheikh_id', _currentUser!['sheikhId'] ?? '');
          await prefs.setString('sheikh_uid', _currentUser!['uid'] ?? '');
        }

        print('[AuthProvider] Session saved to SharedPreferences');
      }
    } catch (e) {
      print('[AuthProvider] Error saving session: $e');
    }
  }

  // Load session from SharedPreferences
  Future<void> _loadSessionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final role = prefs.getString('user_role') ?? '';
      final isAdmin = prefs.getBool('is_admin') ?? false;
      final username = prefs.getString('username') ?? '';
      final email = prefs.getString('email') ?? '';

      if (isLoggedIn && role.isNotEmpty) {
        if (role == 'sheikh') {
          // Handle Sheikh session
          final sheikhId = prefs.getString('sheikh_id') ?? '';
          final sheikhUid = prefs.getString('sheikh_uid') ?? '';

          _currentUser = {
            'uid': sheikhUid,
            'name': username.isNotEmpty ? username : 'شيخ',
            'email': email,
            'role': 'sheikh',
            'sheikhId': sheikhId,
            'is_admin': false,
            'status': 'active',
          };
        } else {
          // Handle other roles (admin, user, etc.)
          _currentUser = {
            'uid': 'admin_$username',
            'name': username,
            'email': email,
            'role': role,
            'username': username,
            'is_admin': isAdmin,
            'status': 'active', // Ensure status is set
          };
        }

        _isLoggedIn = true;
        _isGuest = false;

        // Set admin cache if this is an admin session
        if (role == 'admin' || isAdmin == true) {
          _isAdminCached = true;
          _adminCheckedAt = DateTime.now();
        }

        print(
          '[AuthProvider] Session loaded from SharedPreferences: role=$role, is_admin=$isAdmin, isAdminCached=$_isAdminCached',
        );
      }
    } catch (e) {
      print('[AuthProvider] Error loading session: $e');
    }
  }

  // Login user or sheikh with email/password
  Future<String?> loginUserOrSheikh(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // Use LocalRepository for login
      final result = await _repository.loginUser(
        email: email.trim(),
        password: password,
      );

      if (!result['success']) {
        _setError(result['message'] ?? 'فشل تسجيل الدخول');
        _setLoading(false);
        return null;
      }

      // Get user profile
      final userData = result['user'] as Map<String, dynamic>;
      final userId = userData['id'] as String;
      final userProfile = await _repository.getUserProfile(userId);

      if (userProfile == null) {
        _setError('بيانات المستخدم غير موجودة');
        _setLoading(false);
        return null;
      }

      final isAdmin = userProfile['is_admin'] == true;
      final role = isAdmin ? 'admin' : 'user';

      _currentUser = {
        'uid': userId,
        'id': userId,
        'name': userProfile['name'],
        'username': userProfile['username'],
        'email': userProfile['email'],
        'role': role,
      };
      _isLoggedIn = true;
      _isGuest = false;
      await _saveSessionToPrefs();
      notifyListeners();
      return role;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Login admin or supervisor
  Future<String?> loginAdminOrSupervisor(
    String username,
    String password,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      // Use LocalRepository admin login (supports username or email)
      final result = await _repository.loginAdmin(
        username: username.trim(),
        password: password,
      );

      if (!result['success']) {
        _setError(result['message'] ?? 'بيانات المشرف غير صحيحة');
        _setLoading(false);
        return null;
      }

      // Get admin profile
      final adminData = result['admin'] as Map<String, dynamic>;
      final adminId = adminData['id'] as String;
      final adminProfile = await _repository.getUserProfile(adminId);

      if (adminProfile == null) {
        _setError('بيانات المشرف غير موجودة');
        _setLoading(false);
        return null;
      }

      final role = adminProfile['role'] ?? 'admin';

      _currentUser = {
        'uid': adminId,
        'id': adminId,
        'name': adminProfile['name'] ?? adminData['username'],
        'username': adminData['username'],
        'email': adminData['email'],
        'role': role,
        'is_admin': true,
      };
      _isLoggedIn = true;
      _isGuest = false;
      await _saveSessionToPrefs();
      notifyListeners();
      return role;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Check if the current user is a sheikh assigned to a specific subcategory
  Future<bool> isSheikhAssignedTo(String subcatId) async {
    final uid = currentUid;
    if (currentRole != 'sheikh' || uid == null) {
      return false;
    }
    return await _subcategoryService.isSheikhAssigned(subcatId, uid);
  }

  // Get allowed categories for current Sheikh
  List<String> getAllowedCategories() {
    if (currentRole != 'sheikh' || _currentUser == null) {
      return [];
    }

    final allowedCategories =
        (_currentUser?['allowedCategories'] as List<dynamic>?) ?? [];
    if (allowedCategories.isEmpty) {
      return [];
    }

    return allowedCategories.cast<String>();
  }

  // Check if Sheikh has any allowed categories
  bool hasAllowedCategories() {
    return getAllowedCategories().isNotEmpty;
  }

  // Validate that a category is in the allowed list for current Sheikh
  bool isCategoryAllowed(String category) {
    if (currentRole != 'sheikh') {
      return false;
    }

    final allowedCategories = getAllowedCategories();
    return allowedCategories.contains(category);
  }
}
