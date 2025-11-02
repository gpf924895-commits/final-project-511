import 'package:flutter/material.dart';
// import 'package:new_project/repository/local_repository.dart'; // Reserved for future use

class SheikhProvider extends ChangeNotifier {
  // _repository reserved for future use
  // final LocalRepository _repository = LocalRepository();
  String? _currentSheikhCategoryId;
  Map<String, dynamic>? _sheikhData;
  bool _isLoading = false;
  String? _error;

  String? get currentSheikhCategoryId => _currentSheikhCategoryId;
  Map<String, dynamic>? get sheikhData => _sheikhData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> ensureRoleSheikh() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // For offline-only: sheikh role check is done through auth provider
      // This is a stub that returns true if called
      // The actual role check should be done via AuthProvider
      return true;
    } catch (e) {
      _error = "خطأ في تحميل بيانات الشيخ: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool ensureOwnership(Map<String, dynamic> lecture) {
    if (_currentSheikhCategoryId == null) return false;
    // Ownership check done via lecture's sheikhId field
    return lecture['categoryId'] == _currentSheikhCategoryId;
  }

  void clearData() {
    _currentSheikhCategoryId = null;
    _sheikhData = null;
    _error = null;
    notifyListeners();
  }
}
