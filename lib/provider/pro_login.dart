import 'package:flutter/material.dart';
import 'package:new_project/database/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

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

      final result = await _firebaseService.loginUser(
        email: email.trim(),
        password: password,
      );

      if (result['success']) {
        _isLoggedIn = true;
        _currentUser = result['user'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoggedIn = false;
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
      final result = await _firebaseService.registerUser(
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

      final result = await _firebaseService.loginAdmin(
        username: username.trim(),
        password: password,
      );

      if (result['success']) {
        _isLoggedIn = true;
        _currentUser = result['admin'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Check if user is admin
  bool get isAdmin => _currentUser?['is_admin'] == true;
}