import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class LessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _timeout = Duration(seconds: 10);

  /// Get lesson statistics for a sheikh
  Future<Map<String, int>> getLessonStats(String sheikhUid) async {
    try {
      int totalLessons = 0;
      int publishedCount = 0;
      int draftsCount = 0;
      int thisWeekCount = 0;

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Query all subcategories where this sheikh is assigned
      final subcatsSnapshot = await _firestore
          .collectionGroup('sheikhs')
          .where('sheikhUid', isEqualTo: sheikhUid)
          .get()
          .timeout(_timeout);

      for (final subcatDoc in subcatsSnapshot.docs) {
        // Get chapters for this sheikh
        final chaptersSnapshot = await subcatDoc.reference
            .collection('chapters')
            .get()
            .timeout(_timeout);

        for (final chapterDoc in chaptersSnapshot.docs) {
          // Get lessons for this chapter
          final lessonsSnapshot = await chapterDoc.reference
              .collection('lessons')
              .get()
              .timeout(_timeout);

          for (final lessonDoc in lessonsSnapshot.docs) {
            totalLessons++;
            final data = lessonDoc.data();

            final status = data['status'] ?? 'draft';
            if (status == 'published') {
              publishedCount++;
            } else {
              draftsCount++;
            }

            final createdAt = data['createdAt'];
            if (createdAt is Timestamp) {
              if (createdAt.toDate().isAfter(oneWeekAgo)) {
                thisWeekCount++;
              }
            }
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
  Future<List<Map<String, dynamic>>> listLessons({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    String? status,
    String? search,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Try with orderBy first
      try {
        query = query.orderBy('createdAt', descending: true).limit(limit);
        final snapshot = await query.get().timeout(_timeout);

        var items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Client-side search if provided
        if (search != null && search.trim().isNotEmpty) {
          final searchLower = search.toLowerCase();
          items = items.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            final desc = (item['description'] ?? '').toString().toLowerCase();
            return title.contains(searchLower) || desc.contains(searchLower);
          }).toList();
        }

        return items;
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition') {
          // Fallback without orderBy
          developer.log(
            'Index missing for lessons query, using fallback',
            name: 'LessonService',
          );
          final snapshot = await _firestore
              .collection('subcategories')
              .doc(subcatId)
              .collection('sheikhs')
              .doc(sheikhUid)
              .collection('chapters')
              .doc(chapterId)
              .collection('lessons')
              .limit(limit)
              .get()
              .timeout(_timeout);

          var items = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Client-side sort and filter
          items.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          if (search != null && search.trim().isNotEmpty) {
            final searchLower = search.toLowerCase();
            items = items.where((item) {
              final title = (item['title'] ?? '').toString().toLowerCase();
              final desc = (item['description'] ?? '').toString().toLowerCase();
              return title.contains(searchLower) || desc.contains(searchLower);
            }).toList();
          }

          return items;
        }
        rethrow;
      }
    } on TimeoutException {
      throw LessonServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error listing lessons', name: 'LessonService', error: e);
      throw LessonServiceException('فشل في تحميل الدروس: $e');
    }
  }

  /// Create a new lesson
  Future<String> createLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required Map<String, dynamic> lessonData,
  }) async {
    try {
      // Validate required fields
      if (lessonData['title'] == null ||
          lessonData['title'].toString().trim().isEmpty) {
        throw LessonServiceException('يرجى إدخال عنوان الدرس');
      }

      lessonData['createdAt'] = FieldValue.serverTimestamp();
      lessonData['createdBy'] = sheikhUid;
      lessonData['sheikhUid'] = sheikhUid; // Force sheikhUid field
      lessonData['category'] = subcatId; // Force category field
      lessonData['updatedAt'] = FieldValue.serverTimestamp();
      lessonData['status'] = lessonData['status'] ?? 'draft';

      final docRef = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .add(lessonData)
          .timeout(_timeout);

      developer.log('Lesson created: ${docRef.id}', name: 'LessonService');
      return docRef.id;
    } on TimeoutException {
      throw LessonServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error creating lesson', name: 'LessonService', error: e);
      throw LessonServiceException('فشل في إنشاء الدرس: $e');
    }
  }

  /// Update an existing lesson
  Future<void> updateLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required String lessonId,
    required Map<String, dynamic> lessonData,
  }) async {
    try {
      lessonData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .doc(lessonId)
          .update(lessonData)
          .timeout(_timeout);

      developer.log('Lesson updated: $lessonId', name: 'LessonService');
    } on TimeoutException {
      throw LessonServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error updating lesson', name: 'LessonService', error: e);
      throw LessonServiceException('فشل في تحديث الدرس: $e');
    }
  }

  /// Delete a lesson
  Future<void> deleteLesson({
    required String subcatId,
    required String sheikhUid,
    required String chapterId,
    required String lessonId,
  }) async {
    try {
      // Get lesson data to delete associated media
      final docSnapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .doc(lessonId)
          .get()
          .timeout(_timeout);

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        // Delete media files if they exist
        if (data?['mediaUrl'] != null) {
          try {
            final mediaUrl = data?['mediaUrl'];
            if (mediaUrl != null) {
              final ref = _storage.refFromURL(mediaUrl);
              await ref.delete();
            }
          } catch (e) {
            developer.log(
              'Error deleting media file',
              name: 'LessonService',
              error: e,
            );
          }
        }
        if (data?['thumbnailUrl'] != null) {
          try {
            final thumbnailUrl = data?['thumbnailUrl'];
            if (thumbnailUrl != null) {
              final ref = _storage.refFromURL(thumbnailUrl);
              await ref.delete();
            }
          } catch (e) {
            developer.log(
              'Error deleting thumbnail',
              name: 'LessonService',
              error: e,
            );
          }
        }
      }

      await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .doc(chapterId)
          .collection('lessons')
          .doc(lessonId)
          .delete()
          .timeout(_timeout);

      developer.log('Lesson deleted: $lessonId', name: 'LessonService');
    } on TimeoutException {
      throw LessonServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error deleting lesson', name: 'LessonService', error: e);
      throw LessonServiceException('فشل في حذف الدرس: $e');
    }
  }

  /// List chapters for a sheikh in a subcategory
  Future<List<Map<String, dynamic>>> listChapters({
    required String subcatId,
    required String sheikhUid,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .doc(subcatId)
          .collection('sheikhs')
          .doc(sheikhUid)
          .collection('chapters')
          .orderBy('order', descending: false)
          .get()
          .timeout(_timeout);

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        developer.log(
          'Index missing for chapters query, using fallback',
          name: 'LessonService',
        );
        // Fallback without orderBy
        final snapshot = await _firestore
            .collection('subcategories')
            .doc(subcatId)
            .collection('sheikhs')
            .doc(sheikhUid)
            .collection('chapters')
            .get()
            .timeout(_timeout);

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      throw LessonServiceException('فشل في تحميل الأبواب: ${e.message}');
    } catch (e) {
      developer.log('Error listing chapters', name: 'LessonService', error: e);
      throw LessonServiceException('فشل في تحميل الأبواب: $e');
    }
  }

  /// Upload media file with progress tracking
  Stream<UploadProgress> uploadMedia({
    required File file,
    required String lessonId,
    String? sheikhUid,
  }) async* {
    try {
      final uid = sheikhUid ?? _auth.currentUser?.uid;
      if (uid == null) {
        yield UploadProgress(progress: 0, error: 'يرجى تسجيل الدخول');
        return;
      }

      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final filename = file.path.split(Platform.pathSeparator).last;

      final path = 'lessons_media/$uid/$year/$month/$lessonId/$filename';
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(file);

      await for (final snapshot in uploadTask.snapshotEvents) {
        if (snapshot.state == TaskState.running) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          yield UploadProgress(progress: progress);
        } else if (snapshot.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          yield UploadProgress(
            progress: 1.0,
            downloadUrl: downloadUrl,
            isDone: true,
          );
        } else if (snapshot.state == TaskState.error) {
          yield UploadProgress(progress: 0, error: 'فشل رفع الملف');
        } else if (snapshot.state == TaskState.canceled) {
          yield UploadProgress(progress: 0, error: 'تم إلغاء الرفع');
        }
      }
    } catch (e) {
      developer.log('Error uploading media', name: 'LessonService', error: e);
      yield UploadProgress(progress: 0, error: 'فشل رفع الملف: $e');
    }
  }
}
