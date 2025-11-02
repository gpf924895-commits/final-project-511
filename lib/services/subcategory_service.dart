import 'package:new_project/repository/local_repository.dart';
import 'dart:developer' as developer;

class SubcategoryServiceException implements Exception {
  final String message;
  final String? indexUrl;
  final bool needsIndex;

  SubcategoryServiceException(
    this.message, {
    this.indexUrl,
    this.needsIndex = false,
  });

  @override
  String toString() => message;
}

/// SubcategoryService - Local SQLite implementation
/// Provides sheikh assignment and chapter/lesson management
class SubcategoryService {
  final LocalRepository _repository = LocalRepository();

  // List sheikhs assigned to a subcategory
  // Note: In SQLite, we'll store assignments in a separate table or in lecture data
  Future<List<Map<String, dynamic>>> listSheikhs(String subcatId) async {
    try {
      // For offline-only: Get sheikhs from lectures with this subcategory
      final lectures = await _repository.getLecturesBySubcategory(subcatId);
      final sheikhIds = <String, Map<String, dynamic>>{};

      for (final lecture in lectures) {
        final sheikhId = lecture['sheikhId'] as String?;
        if (sheikhId != null && !sheikhIds.containsKey(sheikhId)) {
          sheikhIds[sheikhId] = {
            'id': sheikhId,
            'sheikhId': sheikhId,
            'sheikhName': lecture['sheikhName'] ?? 'غير محدد',
            'enabled': true,
          };
        }
      }

      return sheikhIds.values.toList();
    } catch (e) {
      developer.log('Error listing sheikhs: $e', name: 'SubcategoryService');
      throw SubcategoryServiceException('فشل في تحميل مشايخ الباب: $e');
    }
  }

  // List chapters for a specific sheikh in a subcategory
  // Note: In SQLite, chapters are stored in the lectures table or a separate chapters table
  Future<List<Map<String, dynamic>>> listChapters(
    String subcatId,
    String sheikhUid,
  ) async {
    try {
      // For offline-only: Return empty list (chapters not yet implemented in LocalRepository)
      // TODO: Implement chapters table in LocalRepository
      return [];
    } catch (e) {
      throw SubcategoryServiceException('فشل في تحميل الأبواب: $e');
    }
  }

  // List lessons for a specific chapter
  Future<List<Map<String, dynamic>>> listLessons(
    String subcatId,
    String sheikhUid,
    String chapterId,
  ) async {
    try {
      // For offline-only: Return empty list (lessons not yet implemented in LocalRepository)
      // TODO: Implement lessons table in LocalRepository
      return [];
    } catch (e) {
      throw SubcategoryServiceException('فشل في تحميل الدروس: $e');
    }
  }

  // Create a new chapter
  Future<String> createChapter(
    String subcatId,
    String sheikhUid,
    String currentUid,
    Map<String, dynamic> chapterData,
  ) async {
    // Guard: assert current uid == sheikhUid
    if (currentUid != sheikhUid) {
      throw SubcategoryServiceException(
        'ليس لديك صلاحية لإضافة محتوى في هذا الباب.',
      );
    }

    try {
      // TODO: Implement chapter creation in LocalRepository
      throw SubcategoryServiceException(
        'إنشاء الأبواب غير مدعوم حالياً في الوضع المحلي',
      );
    } catch (e) {
      if (e is SubcategoryServiceException) rethrow;
      throw SubcategoryServiceException('فشل في إضافة الباب: $e');
    }
  }

  // Create a new lesson
  Future<String> createLesson(
    String subcatId,
    String sheikhUid,
    String chapterId,
    String currentUid,
    Map<String, dynamic> lessonData,
  ) async {
    // Guard: assert current uid == sheikhUid
    if (currentUid != sheikhUid) {
      throw SubcategoryServiceException(
        'ليس لديك صلاحية لإضافة محتوى في هذا الباب.',
      );
    }

    try {
      // TODO: Implement lesson creation in LocalRepository
      throw SubcategoryServiceException(
        'إنشاء الدروس غير مدعوم حالياً في الوضع المحلي',
      );
    } catch (e) {
      if (e is SubcategoryServiceException) rethrow;
      throw SubcategoryServiceException('فشل في إضافة الدرس: $e');
    }
  }

  // Check if a sheikh is assigned to a subcategory
  Future<bool> isSheikhAssigned(String subcatId, String sheikhUid) async {
    try {
      // For offline-only: Check if sheikh has lectures in this subcategory
      final lectures = await _repository.getLecturesBySubcategory(subcatId);
      return lectures.any((lecture) => lecture['sheikhId'] == sheikhUid);
    } catch (e) {
      developer.log(
        'Error checking sheikh assignment: $e',
        name: 'SubcategoryService',
      );
      return false;
    }
  }

  // List all subcategories assigned to a sheikh
  Future<List<Map<String, dynamic>>> listAssignedSubcategories(
    String sheikhUid,
  ) async {
    try {
      // For offline-only: Get unique subcategories from sheikh's lectures
      final lectures = await _repository.getLecturesBySheikh(sheikhUid);
      final subcatIds = <String>{};
      final subcategories = <Map<String, dynamic>>[];

      for (final lecture in lectures) {
        final subcatId = lecture['subcategory_id'] as String?;
        if (subcatId != null && !subcatIds.contains(subcatId)) {
          subcatIds.add(subcatId);
          final subcat = await _repository.getSubcategory(subcatId);
          if (subcat != null) {
            subcategories.add(subcat);
          }
        }
      }

      return subcategories;
    } catch (e) {
      developer.log(
        'Error listing assigned subcategories',
        name: 'SubcategoryService',
        error: e,
      );
      return [];
    }
  }

  // List subcategories filtered by allowed categories for a Sheikh
  Future<List<Map<String, dynamic>>> listAllowedSubcategories(
    String sheikhUid,
    List<String> allowedCategories,
  ) async {
    try {
      if (allowedCategories.isEmpty) {
        return [];
      }

      // Get all assigned subcategories and filter by allowed categories
      final assigned = await listAssignedSubcategories(sheikhUid);

      // Filter by section (which maps to category in our schema)
      return assigned.where((subcat) {
        final section = subcat['section'] as String?;
        return section != null && allowedCategories.contains(section);
      }).toList();
    } catch (e) {
      developer.log(
        'Error listing allowed subcategories',
        name: 'SubcategoryService',
        error: e,
      );
      return [];
    }
  }

  // Update a chapter
  Future<void> updateChapter(
    String subcatId,
    String sheikhUid,
    String chapterId,
    String currentUid,
    Map<String, dynamic> chapterData,
  ) async {
    if (currentUid != sheikhUid) {
      throw SubcategoryServiceException('ليس لديك صلاحية لتعديل هذا الباب.');
    }

    try {
      // TODO: Implement chapter update in LocalRepository
      throw SubcategoryServiceException(
        'تحديث الأبواب غير مدعوم حالياً في الوضع المحلي',
      );
    } catch (e) {
      if (e is SubcategoryServiceException) rethrow;
      throw SubcategoryServiceException('فشل في تحديث الباب: $e');
    }
  }

  // Delete a chapter
  Future<void> deleteChapter(
    String subcatId,
    String sheikhUid,
    String chapterId,
    String currentUid,
  ) async {
    if (currentUid != sheikhUid) {
      throw SubcategoryServiceException('ليس لديك صلاحية لحذف هذا الباب.');
    }

    try {
      // TODO: Implement chapter deletion in LocalRepository
      throw SubcategoryServiceException(
        'حذف الأبواب غير مدعوم حالياً في الوضع المحلي',
      );
    } catch (e) {
      if (e is SubcategoryServiceException) rethrow;
      throw SubcategoryServiceException('فشل في حذف الباب: $e');
    }
  }
}
