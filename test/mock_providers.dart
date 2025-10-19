import 'package:flutter/material.dart';
import 'package:new_project/provider/pro_login.dart';

/// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isGuest = true;
  bool _isReady = true;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isGuest => _isGuest;

  @override
  bool get isAuthenticated => _isLoggedIn && !_isGuest;

  @override
  bool get isReady => _isReady;

  @override
  Map<String, dynamic>? get currentUser => _currentUser;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get currentUid => _currentUser?['uid'];

  @override
  String? get role => _currentUser?['role'];

  @override
  String? get currentRole => _currentUser?['role'];

  // Mock methods
  void setLoggedInUser(Map<String, dynamic> user) {
    _currentUser = user;
    _isLoggedIn = true;
    _isGuest = false;
    _isReady = true;
    notifyListeners();
  }

  void setGuestMode() {
    _currentUser = null;
    _isLoggedIn = false;
    _isGuest = true;
    _isReady = true;
    notifyListeners();
  }

  void setNoSession() {
    _currentUser = null;
    _isLoggedIn = false;
    _isGuest = true;
    _isReady = true;
    notifyListeners();
  }

  void setSheikhSession([Map<String, dynamic>? sheikhData]) {
    _currentUser =
        sheikhData ??
        {
          'uid': 'test-sheikh-id',
          'name': 'الشيخ التجريبي',
          'email': 'sheikh@example.com',
          'role': 'sheikh',
        };
    _isLoggedIn = true;
    _isGuest = false;
    _isReady = true;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    await Future.delayed(const Duration(milliseconds: 100));

    if (email == 'test@test.com' && password == 'password') {
      setLoggedInUser({
        'uid': 'test-uid',
        'email': email,
        'name': 'Test User',
        'role': 'user',
      });
      setLoading(false);
      return true;
    } else {
      setError('Invalid credentials');
      setLoading(false);
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    setGuestMode();
  }

  @override
  void clearError() {
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
