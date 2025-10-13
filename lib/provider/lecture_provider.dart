import 'package:flutter/material.dart';
import 'package:new_project/database/firebase_service.dart';

class LectureProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Map<String, dynamic>> _allLectures = [];
  List<Map<String, dynamic>> _fiqhLectures = [];
  List<Map<String, dynamic>> _hadithLectures = [];
  List<Map<String, dynamic>> _tafsirLectures = [];
  List<Map<String, dynamic>> _seerahLectures = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get allLectures => _allLectures;
  List<Map<String, dynamic>> get fiqhLectures => _fiqhLectures;
  List<Map<String, dynamic>> get hadithLectures => _hadithLectures;
  List<Map<String, dynamic>> get tafsirLectures => _tafsirLectures;
  List<Map<String, dynamic>> get seerahLectures => _seerahLectures;
  
  // Get recent lectures (limit to 5)
  List<Map<String, dynamic>> get recentLectures {
    return _allLectures.take(5).toList();
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
    notifyListeners();
  }

  // Load all lectures
  Future<void> loadAllLectures() async {
    _setLoading(true);
    _setError(null);

    try {
      _allLectures = await _firebaseService.getAllLectures();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل المحاضرات: $e');
    }
  }

  // Load lectures by section
  Future<void> loadLecturesBySection(String section) async {
    _setLoading(true);
    _setError(null);

    try {
      final lectures = await _firebaseService.getLecturesBySection(section);
      
      switch (section) {
        case 'الفقه':
          _fiqhLectures = lectures;
          break;
        case 'الحديث':
          _hadithLectures = lectures;
          break;
        case 'التفسير':
          _tafsirLectures = lectures;
          break;
        case 'السيرة':
          _seerahLectures = lectures;
          break;
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل محاضرات $section: $e');
    }
  }

  // Load all sections
  Future<void> loadAllSections() async {
    _setLoading(true);
    _setError(null);

    try {
      _allLectures = await _firebaseService.getAllLectures();
      _fiqhLectures = await _firebaseService.getLecturesBySection('الفقه');
      _hadithLectures = await _firebaseService.getLecturesBySection('الحديث');
      _tafsirLectures = await _firebaseService.getLecturesBySection('التفسير');
      _seerahLectures = await _firebaseService.getLecturesBySection('السيرة');
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل المحاضرات: $e');
    }
  }

  // Load lectures by subcategory
  Future<List<Map<String, dynamic>>> loadLecturesBySubcategory(String subcategoryId) async {
    _setLoading(true);
    _setError(null);

    try {
      final lectures = await _firebaseService.getLecturesBySubcategory(subcategoryId);
      _setLoading(false);
      return lectures;
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل المحاضرات: $e');
      return [];
    }
  }

  // Add lecture
  Future<bool> addLecture({
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _firebaseService.addLecture(
        title: title,
        description: description,
        videoPath: videoPath,
        section: section,
        subcategoryId: subcategoryId,
      );

      if (result['success']) {
        // Reload the specific section and all lectures
        await loadLecturesBySection(section);
        await loadAllLectures();
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في إضافة المحاضرة: $e');
      return false;
    }
  }

  // Update lecture
  Future<bool> updateLecture({
    required String id,
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _firebaseService.updateLecture(
        id: id,
        title: title,
        description: description,
        videoPath: videoPath,
        section: section,
        subcategoryId: subcategoryId,
      );

      if (result['success']) {
        // Reload the specific section and all lectures
        await loadLecturesBySection(section);
        await loadAllLectures();
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحديث المحاضرة: $e');
      return false;
    }
  }

  // Delete lecture
  Future<bool> deleteLecture(String lectureId, String section) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _firebaseService.deleteLecture(lectureId);

      if (success) {
        // Reload the specific section and all lectures
        await loadLecturesBySection(section);
        await loadAllLectures();
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError('فشل في حذف المحاضرة');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في حذف المحاضرة: $e');
      return false;
    }
  }

  // Search lectures
  Future<List<Map<String, dynamic>>> searchLectures(String query) async {
    try {
      return await _firebaseService.searchLectures(query);
    } catch (e) {
      _setError('حدث خطأ في البحث: $e');
      return [];
    }
  }

  // Get lectures by section without loading state change
  List<Map<String, dynamic>> getLecturesBySection(String section) {
    switch (section) {
      case 'الفقه':
        return _fiqhLectures;
      case 'الحديث':
        return _hadithLectures;
      case 'التفسير':
        return _tafsirLectures;
      case 'السيرة':
        return _seerahLectures;
      default:
        return [];
    }
  }
}

