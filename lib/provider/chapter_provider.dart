import 'package:flutter/material.dart';

class ChapterProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get chapters => _chapters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChapters(String categoryId, String sheikhUid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Implement chapter loading from LocalRepository
      // For now, return empty list
      _chapters = [];
    } catch (e) {
      _error = 'خطأ في تحميل الأبواب: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addChapter({
    required String title,
    required String categoryId,
    required String sheikhUid,
    String? details,
    DateTime? scheduledAt,
    String status = 'draft',
  }) async {
    try {
      // TODO: Implement chapter creation in LocalRepository
      // For now, return null
      await loadChapters(categoryId, sheikhUid);
      return null;
    } catch (e) {
      _error = 'خطأ في إضافة الباب: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateChapter({
    required String chapterId,
    required String title,
    String? details,
    DateTime? scheduledAt,
    String? status,
  }) async {
    try {
      // TODO: Implement chapter update in LocalRepository
      // For now, just update local list
      final index = _chapters.indexWhere(
        (chapter) => chapter['id'] == chapterId,
      );
      if (index != -1) {
        _chapters[index]['title'] = title;
        if (details != null) _chapters[index]['details'] = details;
        if (scheduledAt != null)
          _chapters[index]['scheduledAt'] = scheduledAt.millisecondsSinceEpoch;
        if (status != null) _chapters[index]['status'] = status;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'خطأ في تحديث الباب: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChapter(
    String chapterId,
    String categoryId,
    String sheikhUid,
  ) async {
    try {
      // TODO: Implement chapter deletion in LocalRepository
      // For now, just remove from local list
      _chapters.removeWhere((ch) => ch['id'] == chapterId);

      // Reload chapters
      await loadChapters(categoryId, sheikhUid);
      return true;
    } catch (e) {
      _error = 'خطأ في حذف الباب: $e';
      notifyListeners();
      return false;
    }
  }

  Future<int> getLessonCount(String chapterId) async {
    // TODO: Implement lesson count from LocalRepository
    return 0;
  }

  void clearData() {
    _chapters.clear();
    _error = null;
    notifyListeners();
  }
}
