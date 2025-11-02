import 'package:new_project/repository/local_repository.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;

class LessonServiceException implements Exception {
  final String message;

  LessonServiceException(this.message);

  @override
  String toString() => message;
}

class UploadProgress {
  final double progress;
  final String? downloadUrl;
  final bool isDone;
  final String? error;

  UploadProgress({
    required this.progress,
    this.downloadUrl,
    this.isDone = false,
    this.error,
  });
}

/// LessonService - Local SQLite implementation
/// Provides lesson statistics and management
class LessonService {
  final LocalRepository _repository = LocalRepository();

  /// Get lesson statistics for a sheikh
  Future<Map<String, int>> getLessonStats(String sheikhUid) async {
    try {
      // For offline-only: Get stats from lectures
      final lectures = await _repository.getLecturesBySheikh(sheikhUid);
      int totalLessons = lectures.length;
      int publishedCount = 0;
      int draftsCount = 0;
      int thisWeekCount = 0;

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Count stats from lectures
      for (final lecture in lectures) {
        final status = lecture['status'] as String? ?? 'draft';
        final isPublishedInt = lecture['isPublished'] as int? ?? 0;
        final isPublished = isPublishedInt == 1;

        if (status == 'published' || isPublished) {
          publishedCount++;
        } else if (status != 'archived' && status != 'deleted') {
          draftsCount++;
        }

        final createdAt = lecture['createdAt'] as int?;
        if (createdAt != null) {
          final createdDate = DateTime.fromMillisecondsSinceEpoch(
            createdAt,
            isUtc: true,
          );
          if (createdDate.isAfter(oneWeekAgo)) {
            thisWeekCount++;
          }
        }
      }

      return {
        'total': totalLessons,
        'published': publishedCount,
        'drafts': draftsCount,
        'thisWeek': thisWeekCount,
      };
    } on TimeoutException {
      developer.log('Timeout getting lesson stats', name: 'LessonService');
      return {'total': 0, 'published': 0, 'drafts': 0, 'thisWeek': 0};
    } catch (e) {
      developer.log(
        'Error getting lesson stats',
        name: 'LessonService',
        error: e,
      );
      return {'total': 0, 'published': 0, 'drafts': 0, 'thisWeek': 0};
    }
  }

  /// List lessons with optional filters
  /// TODO: Implement lessons table in LocalRepository
  Future<List<Map<String, dynamic>>> listLessons({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    String? status,
    String? search,
    int limit = 50,
  }) async {
    // For offline-only: Lessons not yet implemented
    // Return empty list for now
    return [];
  }

  /// Create a new lesson
  /// TODO: Implement lessons table in LocalRepository
  Future<String> createLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required Map<String, dynamic> lessonData,
  }) async {
    throw LessonServiceException(
      'إنشاء الدروس غير مدعوم حالياً في الوضع المحلي',
    );
  }

  /// Update an existing lesson
  /// TODO: Implement lessons table in LocalRepository
  Future<void> updateLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required String lessonId,
    required Map<String, dynamic> lessonData,
  }) async {
    throw LessonServiceException(
      'تحديث الدروس غير مدعوم حالياً في الوضع المحلي',
    );
  }

  /// Delete a lesson
  /// TODO: Implement lessons table in LocalRepository
  Future<void> deleteLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required String lessonId,
  }) async {
    throw LessonServiceException('حذف الدروس غير مدعوم حالياً في الوضع المحلي');
  }

  /// List chapters for a specific sheikh in a subcategory
  /// TODO: Implement chapters table in LocalRepository
  Future<List<Map<String, dynamic>>> listChapters({
    required String subcatId,
    required String sheikhUid,
  }) async {
    // For offline-only: Chapters not yet implemented
    return [];
  }

  /// Upload media file with progress tracking
  /// TODO: Implement local file storage
  Stream<UploadProgress> uploadMedia({
    required File file,
    required String lessonId,
    String? sheikhUid,
  }) async* {
    // For offline-only: File uploads not yet implemented
    // Store file path locally instead
    yield UploadProgress(progress: 1.0, downloadUrl: file.path, isDone: true);
  }
}
