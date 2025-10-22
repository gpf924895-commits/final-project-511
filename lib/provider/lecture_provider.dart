import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<List<Map<String, dynamic>>> loadLecturesBySubcategory(
    String subcategoryId,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final lectures = await _firebaseService.getLecturesBySubcategory(
        subcategoryId,
      );
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

  // ==================== Sheikh Lecture Management ====================

  List<Map<String, dynamic>> _sheikhLectures = [];
  Map<String, dynamic>? _sheikhStats;

  // Getters for sheikh lectures
  List<Map<String, dynamic>> get sheikhLectures => _sheikhLectures;
  Map<String, dynamic>? get sheikhStats => _sheikhStats;

  // Load lectures for current sheikh
  Future<void> loadSheikhLectures(String sheikhId) async {
    _setLoading(true);
    _setError(null);

    try {
      _sheikhLectures = await _firebaseService.getLecturesBySheikh(sheikhId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل محاضرات الشيخ: $e');
    }
  }

  // Load sheikh lecture statistics
  Future<void> loadSheikhStats(String sheikhId) async {
    try {
      _sheikhStats = await _firebaseService.getSheikhLectureStats(sheikhId);
      notifyListeners();
    } catch (e) {
      print('Error loading sheikh stats: $e');
    }
  }

  // Add lecture for sheikh
  Future<bool> addSheikhLecture({
    required String sheikhId,
    required String sheikhName,
    required String section,
    required String categoryId,
    required String categoryName,
    String? subcategoryId,
    String? subcategoryName,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check for overlapping lectures
      final hasOverlap = await _firebaseService.hasOverlappingLectures(
        sheikhId: sheikhId,
        startTime: Timestamp.fromDate(startTime),
        endTime: endTime != null ? Timestamp.fromDate(endTime) : null,
      );

      if (hasOverlap) {
        _setLoading(false);
        _setError('يوجد محاضرة أخرى في نفس الوقت');
        return false;
      }

      final result = await _firebaseService.addSheikhLecture(
        sheikhId: sheikhId,
        sheikhName: sheikhName,
        section: section,
        categoryId: categoryId,
        categoryName: categoryName,
        subcategoryId: subcategoryId,
        subcategoryName: subcategoryName,
        title: title,
        description: description,
        startTime: Timestamp.fromDate(startTime),
        endTime: endTime != null ? Timestamp.fromDate(endTime) : null,
        location: location,
        media: media,
      );

      if (result['success']) {
        // Reload sheikh lectures and stats
        await loadSheikhLectures(sheikhId);
        await loadSheikhStats(sheikhId);
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

  // Update sheikh lecture
  Future<bool> updateSheikhLecture({
    required String lectureId,
    required String sheikhId,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check for overlapping lectures (excluding current lecture)
      final hasOverlap = await _firebaseService.hasOverlappingLectures(
        sheikhId: sheikhId,
        startTime: Timestamp.fromDate(startTime),
        endTime: endTime != null ? Timestamp.fromDate(endTime) : null,
        excludeLectureId: lectureId,
      );

      if (hasOverlap) {
        _setLoading(false);
        _setError('يوجد محاضرة أخرى في نفس الوقت');
        return false;
      }

      final result = await _firebaseService.updateSheikhLecture(
        lectureId: lectureId,
        sheikhId: sheikhId,
        title: title,
        description: description,
        startTime: Timestamp.fromDate(startTime),
        endTime: endTime != null ? Timestamp.fromDate(endTime) : null,
        location: location,
        media: media,
      );

      if (result['success']) {
        // Reload sheikh lectures and stats
        await loadSheikhLectures(sheikhId);
        await loadSheikhStats(sheikhId);
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

  // Archive sheikh lecture
  Future<bool> archiveSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _firebaseService.archiveSheikhLecture(
        lectureId: lectureId,
        sheikhId: sheikhId,
      );

      if (result['success']) {
        // Reload sheikh lectures and stats
        await loadSheikhLectures(sheikhId);
        await loadSheikhStats(sheikhId);
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في أرشفة المحاضرة: $e');
      return false;
    }
  }

  // Permanently delete sheikh lecture
  Future<bool> deleteSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _firebaseService.deleteSheikhLecture(
        lectureId: lectureId,
        sheikhId: sheikhId,
      );

      if (result['success']) {
        // Reload sheikh lectures and stats
        await loadSheikhLectures(sheikhId);
        await loadSheikhStats(sheikhId);
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في حذف المحاضرة: $e');
      return false;
    }
  }

  // Get lectures by sheikh and category
  Future<List<Map<String, dynamic>>> loadSheikhLecturesByCategory(
    String sheikhId,
    String categoryKey,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final lectures = await _firebaseService.getLecturesBySheikhAndCategory(
        sheikhId,
        categoryKey,
      );
      _setLoading(false);
      return lectures;
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل محاضرات الفئة: $e');
      return [];
    }
  }

  // Clear sheikh data
  void clearSheikhData() {
    _sheikhLectures = [];
    _sheikhStats = null;
    notifyListeners();
  }
}
