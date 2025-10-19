import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      final query = await FirebaseFirestore.instance
          .collection('chapters')
          .where('categoryId', isEqualTo: categoryId)
          .where('sheikhUid', isEqualTo: sheikhUid)
          .orderBy('createdAt', descending: true)
          .get();

      _chapters = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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
      final now = DateTime.now();
      final chapterData = {
        'title': title,
        'details': details ?? '',
        'categoryId': categoryId,
        'sheikhUid': sheikhUid,
        'createdBy': sheikhUid,
        'status': status,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('chapters')
          .add(chapterData);

      // Reload chapters
      await loadChapters(categoryId, sheikhUid);
      return docRef.id;
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
      final updateData = {
        'title': title,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        if (details != null) 'details': details,
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
        if (status != null) 'status': status,
      };

      await FirebaseFirestore.instance
          .collection('chapters')
          .doc(chapterId)
          .update(updateData);

      // Update local list
      final index = _chapters.indexWhere(
        (chapter) => chapter['id'] == chapterId,
      );
      if (index != -1) {
        _chapters[index].addAll(updateData);
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
      // First, get all lessons in this chapter
      final lessonsQuery = await FirebaseFirestore.instance
          .collection('lectures')
          .where('chapterId', isEqualTo: chapterId)
          .get();

      // Delete all lessons in this chapter
      final batch = FirebaseFirestore.instance.batch();
      for (final lesson in lessonsQuery.docs) {
        batch.delete(lesson.reference);
      }

      // Delete the chapter
      batch.delete(
        FirebaseFirestore.instance.collection('chapters').doc(chapterId),
      );

      await batch.commit();

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
    try {
      final query = await FirebaseFirestore.instance
          .collection('lectures')
          .where('chapterId', isEqualTo: chapterId)
          .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  void clearData() {
    _chapters.clear();
    _error = null;
    notifyListeners();
  }
}
