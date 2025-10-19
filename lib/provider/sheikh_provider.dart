import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SheikhProvider extends ChangeNotifier {
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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = "المستخدم غير مسجل الدخول";
        return false;
      }

      // Check user role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'sheikh') {
        _error = "هذه الصفحة خاصة بالشيخ";
        return false;
      }

      // Get sheikh data and category
      final sheikhDoc = await FirebaseFirestore.instance
          .collection('sheikhs')
          .doc(user.uid)
          .get();

      if (!sheikhDoc.exists) {
        _error = "بيانات الشيخ غير موجودة";
        return false;
      }

      _sheikhData = sheikhDoc.data();
      _currentSheikhCategoryId = _sheikhData?['categoryId'];

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

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return false;

    return lecture['createdBy'] == currentUid &&
        lecture['sheikhUid'] == currentUid &&
        lecture['categoryId'] == _currentSheikhCategoryId;
  }

  void clearData() {
    _currentSheikhCategoryId = null;
    _sheikhData = null;
    _error = null;
    notifyListeners();
  }
}

