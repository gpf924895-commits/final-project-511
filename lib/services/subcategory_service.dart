import 'package:cloud_firestore/cloud_firestore.dart';
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

class SubcategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List sheikhs assigned to a subcategory
  Future<List<Map<String, dynamic>>> listSheikhs(String subcatId) async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .where('enabled', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      // Check if this is an index requirement error
      if (e.code == 'failed-precondition' && e.message != null) {
        // Extract index creation URL from error message
        final message = e.message ?? 'Unknown error';
        String? indexUrl;

        // Firestore error messages contain the index URL
        final urlMatch = RegExp(
          r'https://console\.firebase\.google\.com[^\s]+',
        ).firstMatch(message);
        if (urlMatch != null) {
          indexUrl = urlMatch.group(0);
          developer.log(
            'Firestore Index Required for Sheikhs Query',
            name: 'SubcategoryService',
            error: 'Missing composite index',
          );
          developer.log(
            'Create index at: $indexUrl',
            name: 'SubcategoryService',
          );
        }

        throw SubcategoryServiceException(
          'يتطلب هذا الاستعلام إنشاء فهرس في قاعدة البيانات. يرجى إنشاء الفهرس والمحاولة مرة أخرى.',
          indexUrl: indexUrl,
          needsIndex: true,
        );
      }
      throw SubcategoryServiceException(
        'فشل في تحميل مشايخ الباب: ${e.message}',
      );
    } catch (e) {
      throw SubcategoryServiceException('فشل في تحميل مشايخ الباب: $e');
    }
  }

  // List chapters for a specific sheikh in a subcategory
  Future<List<Map<String, dynamic>>> listChapters(
    String subcatId,
    String sheikhUid,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' && e.message != null) {
        final message = e.message ?? 'Unknown error';
        String? indexUrl;

        final urlMatch = RegExp(
          r'https://console\.firebase\.google\.com[^\s]+',
        ).firstMatch(message);
        if (urlMatch != null) {
          indexUrl = urlMatch.group(0);
          developer.log(
            'Firestore Index Required for Chapters Query',
            name: 'SubcategoryService',
            error: 'Missing index',
          );
          developer.log(
            'Create index at: $indexUrl',
            name: 'SubcategoryService',
          );
        }

        throw SubcategoryServiceException(
          'يتطلب هذا الاستعلام إنشاء فهرس في قاعدة البيانات. يرجى إنشاء الفهرس والمحاولة مرة أخرى.',
          indexUrl: indexUrl,
          needsIndex: true,
        );
      }
      throw SubcategoryServiceException('فشل في تحميل الأبواب: ${e.message}');
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
      final snapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' && e.message != null) {
        final message = e.message ?? 'Unknown error';
        String? indexUrl;

        final urlMatch = RegExp(
          r'https://console\.firebase\.google\.com[^\s]+',
        ).firstMatch(message);
        if (urlMatch != null) {
          indexUrl = urlMatch.group(0);
          developer.log(
            'Firestore Index Required for Lessons Query',
            name: 'SubcategoryService',
            error: 'Missing index',
          );
          developer.log(
            'Create index at: $indexUrl',
            name: 'SubcategoryService',
          );
        }

        throw SubcategoryServiceException(
          'يتطلب هذا الاستعلام إنشاء فهرس في قاعدة البيانات. يرجى إنشاء الفهرس والمحاولة مرة أخرى.',
          indexUrl: indexUrl,
          needsIndex: true,
        );
      }
      throw SubcategoryServiceException('فشل في تحميل الدروس: ${e.message}');
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
      final docRef = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .add({
            'title': chapterData['title'],
            'order': chapterData['order'] ?? 0,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentUid,
            'sheikhUid': sheikhUid, // Force sheikhUid field
            'category': subcatId, // Force category field
            'sheikhName': chapterData['sheikhName'],
            'scheduledAt': chapterData['scheduledAt'],
            'details': chapterData['details'],
            'status': chapterData['status'] ?? 'draft',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return docRef.id;
    } catch (e) {
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
      final docRef = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .add({
            'title': lessonData['title'],
            'description': lessonData['description'] ?? '',
            'mediaUrl': lessonData['mediaUrl'],
            'duration': lessonData['duration'],
            'order': lessonData['order'] ?? 0,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentUid,
          });

      return docRef.id;
    } catch (e) {
      throw SubcategoryServiceException('فشل في إضافة الدرس: $e');
    }
  }

  // Check if a sheikh is assigned to a subcategory
  Future<bool> isSheikhAssigned(String subcatId, String sheikhUid) async {
    try {
      final doc = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .get();

      return doc.exists && (doc.data()?['enabled'] == true);
    } catch (e) {
      return false;
    }
  }

  // List all subcategories assigned to a sheikh
  Future<List<Map<String, dynamic>>> listAssignedSubcategories(
    String sheikhUid,
  ) async {
    try {
      // Use collectionGroup to find all sheikh assignments
      final snapshot = await _firestore
          .collectionGroup('sheikhs')
          .where('sheikhUid', isEqualTo: sheikhUid)
          .where('enabled', isEqualTo: true)
          .get();

      final assignments = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        // Get parent subcategory document
        final subcatRef = doc.reference.parent.parent;
        if (subcatRef != null) {
          final subcatDoc = await subcatRef.get();
          if (subcatDoc.exists) {
            final data = subcatDoc.data() as Map<String, dynamic>;
            data['id'] = subcatDoc.id;
            assignments.add(data);
          }
        }
      }

      return assignments;
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

      // Query subcategories where category is in allowedCategories
      final snapshot = await _firestore
          .collection('subcategories')
          .where('category', whereIn: allowedCategories)
          .get();

      final subcategories = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        // Check if this sheikh is assigned to this subcategory
        final sheikhAssignment = await _firestore
            .collection('subcategories')
            .doc(doc.id)
            .collection('sheikhs')
            .doc(sheikhUid)
            .get();

        if (sheikhAssignment.exists &&
            (sheikhAssignment.data()?['enabled'] == true)) {
          final data = doc.data();
          data['id'] = doc.id;
          subcategories.add(data);
        }
      }

      return subcategories;
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
      await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .update({
            'title': chapterData['title'],
            'order': chapterData['order'] ?? 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
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
      // Delete all lessons first
      final lessonsSnapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .get();

      for (final lessonDoc in lessonsSnapshot.docs) {
        await lessonDoc.reference.delete();
      }

      // Delete the chapter
      await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .delete();
    } catch (e) {
      throw SubcategoryServiceException('فشل في حذف الباب: $e');
    }
  }
}
