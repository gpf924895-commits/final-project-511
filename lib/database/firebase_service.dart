import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService._internal();

  factory FirebaseService() => _instance;

  // Collections
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get lecturesCollection =>
      _firestore.collection('lectures');
  CollectionReference get subcategoriesCollection =>
      _firestore.collection('subcategories');

  // ==================== User Management ====================

  // Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      final querySnapshot = await usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {'success': false, 'message': 'الإيميل موجود مسبقاً'};
      }

      // Create new user document
      final docRef = await usersCollection.add({
        'username': username,
        'email': email,
        'password':
            password, // Note: In production, use proper password hashing
        'is_admin': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح',
        'user_id': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الحساب: $e'};
    }
  }

  // User login
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final querySnapshot = await usersCollection
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'الإيميل أو كلمة المرور غير صحيحة',
        };
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;

      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'user': {
          'id': userDoc.id,
          'username': userData['username'],
          'email': userData['email'],
          'is_admin': userData['is_admin'] ?? false,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول: $e'};
    }
  }

  // Admin login
  Future<Map<String, dynamic>> loginAdmin({
    required String username,
    required String password,
  }) async {
    try {
      // Search by username or email
      var querySnapshot = await usersCollection
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .where('is_admin', isEqualTo: true)
          .limit(1)
          .get();

      // If not found by username, try email
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await usersCollection
            .where('email', isEqualTo: username)
            .where('password', isEqualTo: password)
            .where('is_admin', isEqualTo: true)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'بيانات المشرف غير صحيحة'};
      }

      final adminDoc = querySnapshot.docs.first;
      final adminData = adminDoc.data() as Map<String, dynamic>;

      return {
        'success': true,
        'message': 'مرحباً بك أيها المشرف',
        'admin': {
          'id': adminDoc.id,
          'username': adminData['username'],
          'email': adminData['email'],
          'is_admin': true,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل دخول المشرف: $e',
      };
    }
  }

  // Create admin account
  Future<Map<String, dynamic>> createAdminAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if user already exists
      var querySnapshot = await usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {'success': false, 'message': 'الإيميل موجود مسبقاً'};
      }

      querySnapshot = await usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {'success': false, 'message': 'اسم المستخدم موجود مسبقاً'};
      }

      // Create admin user
      final docRef = await usersCollection.add({
        'username': username,
        'email': email,
        'password': password,
        'is_admin': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'تم إنشاء حساب المشرف بنجاح',
        'admin_id': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إنشاء حساب المشرف: $e',
      };
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await usersCollection
          .where('is_admin', isEqualTo: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? gender,
    String? birthDate,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (gender != null) updateData['gender'] = gender;
      if (birthDate != null) updateData['birth_date'] = birthDate;
      if (profileImageUrl != null)
        updateData['profile_image_url'] = profileImageUrl;

      updateData['updated_at'] = FieldValue.serverTimestamp();

      await usersCollection.doc(userId).update(updateData);

      return {'success': true, 'message': 'تم تحديث الملف الشخصي بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الملف الشخصي: $e',
      };
    }
  }

  // Change user password
  Future<Map<String, dynamic>> changeUserPassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // First, verify the old password
      final docSnapshot = await usersCollection.doc(userId).get();
      if (!docSnapshot.exists) {
        return {'success': false, 'message': 'المستخدم غير موجود'};
      }

      final userData = docSnapshot.data() as Map<String, dynamic>;
      if (userData['password'] != oldPassword) {
        return {'success': false, 'message': 'كلمة المرور القديمة غير صحيحة'};
      }

      // Update password
      await usersCollection.doc(userId).update({
        'password': newPassword,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تغيير كلمة المرور بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تغيير كلمة المرور: $e',
      };
    }
  }

  // ==================== Subcategory Management ====================

  // Get subcategories by section
  Future<List<Map<String, dynamic>>> getSubcategoriesBySection(
    String section,
  ) async {
    try {
      final querySnapshot = await subcategoriesCollection
          .where('section', isEqualTo: section)
          .get();

      // Sort locally by created_at if available
      final subcategories = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by created_at timestamp if it exists
      subcategories.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      return subcategories;
    } catch (e) {
      print('Error loading subcategories for section $section: $e');
      return [];
    }
  }

  // Get a single subcategory
  Future<Map<String, dynamic>?> getSubcategory(String id) async {
    try {
      final docSnapshot = await subcategoriesCollection.doc(id).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Add subcategory
  Future<Map<String, dynamic>> addSubcategory({
    required String name,
    required String section,
    String? description,
    String? iconName,
  }) async {
    try {
      final docRef = await subcategoriesCollection.add({
        'name': name,
        'section': section,
        'description': description,
        'icon_name': iconName,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'تم إضافة الفئة الفرعية بنجاح',
        'subcategory_id': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إضافة الفئة الفرعية: $e',
      };
    }
  }

  // Update subcategory
  Future<Map<String, dynamic>> updateSubcategory({
    required String id,
    required String name,
    String? description,
    String? iconName,
  }) async {
    try {
      await subcategoriesCollection.doc(id).update({
        'name': name,
        'description': description,
        'icon_name': iconName,
      });

      return {'success': true, 'message': 'تم تحديث الفئة الفرعية بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الفئة الفرعية: $e',
      };
    }
  }

  // Delete subcategory
  Future<bool> deleteSubcategory(String subcategoryId) async {
    try {
      await subcategoriesCollection.doc(subcategoryId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== Lecture Management ====================

  // Add lecture
  Future<Map<String, dynamic>> addLecture({
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    try {
      final docRef = await lecturesCollection.add({
        'title': title,
        'description': description,
        'video_path': videoPath,
        'section': section,
        'subcategory_id': subcategoryId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'تم إضافة المحاضرة بنجاح',
        'lecture_id': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة المحاضرة: $e'};
    }
  }

  // Get all lectures
  Future<List<Map<String, dynamic>>> getAllLectures() async {
    try {
      final querySnapshot = await lecturesCollection
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get lectures by section
  Future<List<Map<String, dynamic>>> getLecturesBySection(
    String section,
  ) async {
    try {
      final querySnapshot = await lecturesCollection
          .where('section', isEqualTo: section)
          .get();

      // Sort locally by created_at
      final lectures = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      lectures.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // descending
      });

      return lectures;
    } catch (e) {
      print('Error loading lectures for section $section: $e');
      return [];
    }
  }

  // Get lectures by subcategory
  Future<List<Map<String, dynamic>>> getLecturesBySubcategory(
    String subcategoryId,
  ) async {
    try {
      final querySnapshot = await lecturesCollection
          .where('subcategory_id', isEqualTo: subcategoryId)
          .get();

      // Sort locally by created_at
      final lectures = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      lectures.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // descending
      });

      return lectures;
    } catch (e) {
      print('Error loading lectures for subcategory $subcategoryId: $e');
      return [];
    }
  }

  // Get a single lecture
  Future<Map<String, dynamic>?> getLecture(String id) async {
    try {
      final docSnapshot = await lecturesCollection.doc(id).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update lecture
  Future<Map<String, dynamic>> updateLecture({
    required String id,
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    try {
      await lecturesCollection.doc(id).update({
        'title': title,
        'description': description,
        'video_path': videoPath,
        'section': section,
        'subcategory_id': subcategoryId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تحديث المحاضرة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث المحاضرة: $e'};
    }
  }

  // Delete lecture
  Future<bool> deleteLecture(String lectureId) async {
    try {
      await lecturesCollection.doc(lectureId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Search lectures
  Future<List<Map<String, dynamic>>> searchLectures(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // We'll get all lectures and filter locally
      // For production, consider using Algolia or similar service
      final querySnapshot = await lecturesCollection.get();

      final allLectures = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter locally
      return allLectures.where((lecture) {
        final title = lecture['title']?.toString().toLowerCase() ?? '';
        final description =
            lecture['description']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Sheikh Lecture Management ====================

  // Add lecture for Sheikh (with new data model)
  Future<Map<String, dynamic>> addSheikhLecture({
    required String sheikhId,
    required String sheikhName,
    required String categoryKey,
    required String categoryNameAr,
    required String title,
    String? description,
    required Timestamp startTime,
    Timestamp? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      final docRef = await lecturesCollection.add({
        'sheikhId': sheikhId,
        'sheikhName': sheikhName,
        'categoryKey': categoryKey,
        'categoryNameAr': categoryNameAr,
        'title': title,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'status': 'draft',
        'media': media,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'تم إضافة المحاضرة بنجاح',
        'lecture_id': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة المحاضرة: $e'};
    }
  }

  // Get lectures by Sheikh ID
  Future<List<Map<String, dynamic>>> getLecturesBySheikh(
    String sheikhId,
  ) async {
    try {
      final querySnapshot = await lecturesCollection
          .where('sheikhId', isEqualTo: sheikhId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading lectures for sheikh $sheikhId: $e');
      return [];
    }
  }

  // Get lectures by Sheikh ID and category
  Future<List<Map<String, dynamic>>> getLecturesBySheikhAndCategory(
    String sheikhId,
    String categoryKey,
  ) async {
    try {
      final querySnapshot = await lecturesCollection
          .where('sheikhId', isEqualTo: sheikhId)
          .where('categoryKey', isEqualTo: categoryKey)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print(
        'Error loading lectures for sheikh $sheikhId and category $categoryKey: $e',
      );
      return [];
    }
  }

  // Update Sheikh lecture
  Future<Map<String, dynamic>> updateSheikhLecture({
    required String lectureId,
    required String sheikhId,
    required String title,
    String? description,
    required Timestamp startTime,
    Timestamp? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      // Verify the lecture belongs to the sheikh
      final lectureDoc = await lecturesCollection.doc(lectureId).get();
      if (!lectureDoc.exists) {
        return {'success': false, 'message': 'المحاضرة غير موجودة'};
      }

      final lectureData = lectureDoc.data() as Map<String, dynamic>;
      if (lectureData['sheikhId'] != sheikhId) {
        return {'success': false, 'message': 'غير مصرح بتعديل هذه المحاضرة'};
      }

      await lecturesCollection.doc(lectureId).update({
        'title': title,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'media': media,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تحديث المحاضرة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث المحاضرة: $e'};
    }
  }

  // Archive Sheikh lecture (soft delete)
  Future<Map<String, dynamic>> archiveSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    try {
      // Verify the lecture belongs to the sheikh
      final lectureDoc = await lecturesCollection.doc(lectureId).get();
      if (!lectureDoc.exists) {
        return {'success': false, 'message': 'المحاضرة غير موجودة'};
      }

      final lectureData = lectureDoc.data() as Map<String, dynamic>;
      if (lectureData['sheikhId'] != sheikhId) {
        return {'success': false, 'message': 'غير مصرح بحذف هذه المحاضرة'};
      }

      await lecturesCollection.doc(lectureId).update({
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم أرشفة المحاضرة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء أرشفة المحاضرة: $e'};
    }
  }

  // Permanently delete Sheikh lecture
  Future<Map<String, dynamic>> deleteSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    try {
      // Verify the lecture belongs to the sheikh
      final lectureDoc = await lecturesCollection.doc(lectureId).get();
      if (!lectureDoc.exists) {
        return {'success': false, 'message': 'المحاضرة غير موجودة'};
      }

      final lectureData = lectureDoc.data() as Map<String, dynamic>;
      if (lectureData['sheikhId'] != sheikhId) {
        return {'success': false, 'message': 'غير مصرح بحذف هذه المحاضرة'};
      }

      await lecturesCollection.doc(lectureId).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم حذف المحاضرة نهائياً'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء حذف المحاضرة: $e'};
    }
  }

  // Check for overlapping lecture times
  Future<bool> hasOverlappingLectures({
    required String sheikhId,
    required Timestamp startTime,
    Timestamp? endTime,
    String? excludeLectureId,
  }) async {
    try {
      Query query = lecturesCollection
          .where('sheikhId', isEqualTo: sheikhId)
          .where('status', whereIn: ['draft', 'published']);

      if (excludeLectureId != null) {
        query = query.where(
          FieldPath.documentId,
          isNotEqualTo: excludeLectureId,
        );
      }

      final querySnapshot = await query.get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingStart = data['startTime'] as Timestamp;
        final existingEnd = data['endTime'] as Timestamp?;

        // Check for overlap
        if (endTime != null && existingEnd != null) {
          // Both have end times - check if they overlap
          if (startTime.toDate().isBefore(existingEnd.toDate()) &&
              endTime.toDate().isAfter(existingStart.toDate())) {
            return true;
          }
        } else if (endTime != null) {
          // New lecture has end time, existing doesn't
          if (startTime.toDate().isBefore(existingStart.toDate()) &&
              endTime.toDate().isAfter(existingStart.toDate())) {
            return true;
          }
        } else if (existingEnd != null) {
          // Existing lecture has end time, new doesn't
          if (startTime.toDate().isBefore(existingEnd.toDate()) &&
              startTime.toDate().isAfter(existingStart.toDate())) {
            return true;
          }
        } else {
          // Neither has end time - check if start times are the same
          if (startTime.toDate().isAtSameMomentAs(existingStart.toDate())) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking overlapping lectures: $e');
      return false;
    }
  }

  // Get Sheikh lecture statistics
  Future<Map<String, dynamic>> getSheikhLectureStats(String sheikhId) async {
    try {
      final querySnapshot = await lecturesCollection
          .where('sheikhId', isEqualTo: sheikhId)
          .get();

      int totalLectures = 0;
      int upcomingToday = 0;
      Timestamp? lastUpdated;

      final now = Timestamp.now();
      final todayStart = Timestamp.fromDate(
        DateTime(now.toDate().year, now.toDate().month, now.toDate().day),
      );
      final todayEnd = Timestamp.fromDate(
        DateTime(
          now.toDate().year,
          now.toDate().month,
          now.toDate().day,
          23,
          59,
          59,
        ),
      );

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status != 'archived' && status != 'deleted') {
          totalLectures++;

          final startTime = data['startTime'] as Timestamp;
          if (startTime.toDate().isAfter(todayStart.toDate()) &&
              startTime.toDate().isBefore(todayEnd.toDate())) {
            upcomingToday++;
          }

          final updatedAt = data['updatedAt'] as Timestamp?;
          if (updatedAt != null &&
              (lastUpdated == null ||
                  updatedAt.toDate().isAfter(lastUpdated.toDate()))) {
            lastUpdated = updatedAt;
          }
        }
      }

      return {
        'totalLectures': totalLectures,
        'upcomingToday': upcomingToday,
        'lastUpdated': lastUpdated,
      };
    } catch (e) {
      print('Error getting sheikh lecture stats: $e');
      return {'totalLectures': 0, 'upcomingToday': 0, 'lastUpdated': null};
    }
  }

  // ==================== Database Initialization ====================

  // Initialize default subcategories
  Future<void> initializeDefaultSubcategories() async {
    try {
      // Check if subcategories already exist
      final existingSubcategories = await subcategoriesCollection
          .limit(1)
          .get();
      if (existingSubcategories.docs.isNotEmpty) {
        return; // Already initialized
      }

      final now = Timestamp.now();

      // Fiqh subcategories
      await subcategoriesCollection.add({
        'name': 'العبادات',
        'section': 'الفقه',
        'description': 'أحكام الصلاة والصيام والزكاة والحج',
        'icon_name': 'mosque',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'المعاملات',
        'section': 'الفقه',
        'description': 'البيوع والعقود والمعاملات المالية',
        'icon_name': 'handshake',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'الأحوال الشخصية',
        'section': 'الفقه',
        'description': 'النكاح والطلاق والميراث',
        'icon_name': 'family',
        'created_at': now,
      });

      // Hadith subcategories
      await subcategoriesCollection.add({
        'name': 'الصحيحان',
        'section': 'الحديث',
        'description': 'أحاديث البخاري ومسلم',
        'icon_name': 'book',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'السنن الأربعة',
        'section': 'الحديث',
        'description': 'أبو داود والترمذي والنسائي وابن ماجه',
        'icon_name': 'books',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'الأربعين النووية',
        'section': 'الحديث',
        'description': 'شرح الأربعين النووية',
        'icon_name': 'list',
        'created_at': now,
      });

      // Tafsir subcategories
      await subcategoriesCollection.add({
        'name': 'تفسير القرآن الكريم',
        'section': 'التفسير',
        'description': 'تفسير السور والآيات',
        'icon_name': 'quran',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'أسباب النزول',
        'section': 'التفسير',
        'description': 'قصص وأسباب نزول الآيات',
        'icon_name': 'history',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'علوم القرآن',
        'section': 'التفسير',
        'description': 'الناسخ والمنسوخ والمحكم والمتشابه',
        'icon_name': 'school',
        'created_at': now,
      });

      // Seerah subcategories
      await subcategoriesCollection.add({
        'name': 'السيرة المكية',
        'section': 'السيرة',
        'description': 'حياة النبي في مكة',
        'icon_name': 'location',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'السيرة المدنية',
        'section': 'السيرة',
        'description': 'حياة النبي في المدينة',
        'icon_name': 'location',
        'created_at': now,
      });

      await subcategoriesCollection.add({
        'name': 'الغزوات',
        'section': 'السيرة',
        'description': 'غزوات النبي صلى الله عليه وسلم',
        'icon_name': 'flag',
        'created_at': now,
      });
    } catch (e) {
      print('Error initializing subcategories: $e');
    }
  }

  // Get user by uniqueId and role
  Future<Map<String, dynamic>?> getUserByUniqueId(
    String uniqueId, {
    String role = 'sheikh',
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: uniqueId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting user by uniqueId: $e');
      return null;
    }
  }

  // Delete sheikh by uniqueId with dual schema support
  Future<Map<String, dynamic>> deleteSheikhByUniqueId(String uniqueId) async {
    try {
      // Pad input to 8 digits
      final padded = uniqueId.trim().padLeft(8, '0');
      print('[FirebaseService] Delete sheikh attempt:');
      print('  - input: $uniqueId');
      print('  - padded: $padded');

      // Try sheikhs collection first (preferred schema)
      DocumentSnapshot? sheikhDoc;
      Map<String, dynamic>? sheikhData;
      String? sheikhName;
      String? sheikhUid;

      try {
        sheikhDoc = await _firestore.collection('sheikhs').doc(padded).get();
        if (sheikhDoc.exists) {
          sheikhData = sheikhDoc.data() as Map<String, dynamic>?;
          sheikhName = sheikhData?['name'] ?? 'غير محدد';
          sheikhUid = sheikhDoc.id; // Use doc ID as UID
          print('[FirebaseService] Found in sheikhs collection: $sheikhName');
        }
      } catch (e) {
        print('[FirebaseService] Error querying sheikhs collection: $e');
      }

      // If not found in sheikhs, try users collection (legacy schema)
      if (sheikhData == null) {
        try {
          final usersQuery = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'sheikh')
              .where('uniqueId', isEqualTo: padded)
              .limit(1)
              .get();

          if (usersQuery.docs.isNotEmpty) {
            final doc = usersQuery.docs.first;
            sheikhData = doc.data();
            sheikhName = sheikhData['name'] ?? 'غير محدد';
            sheikhUid = doc.id;
            print('[FirebaseService] Found in users collection: $sheikhName');
          }
        } catch (e) {
          print('[FirebaseService] Error querying users collection: $e');
        }
      }

      if (sheikhData == null) {
        return {
          'success': false,
          'message': 'لم يتم العثور على شيخ بهذا الرقم',
        };
      }

      print('[FirebaseService] Found sheikh: $sheikhName (UID: $sheikhUid)');

      // Archive lectures by this sheikh
      if (sheikhUid != null) {
        await archiveLecturesBySheikh(sheikhUid);
        print('[FirebaseService] Archived lectures for sheikh: $sheikhUid');
      }

      // Delete the sheikh document from the appropriate collection
      if (sheikhDoc != null && sheikhDoc.exists) {
        // Delete from sheikhs collection
        await _firestore.collection('sheikhs').doc(padded).delete();
        print('[FirebaseService] Deleted from sheikhs collection: $padded');
      } else if (sheikhUid != null) {
        // Delete from users collection
        await _firestore.collection('users').doc(sheikhUid).delete();
        print('[FirebaseService] Deleted from users collection: $sheikhUid');
      }

      return {
        'success': true,
        'message': 'تم حذف الشيخ وجميع محاضراته بنجاح',
        'sheikhName': sheikhName,
      };
    } catch (e) {
      print('[FirebaseService] Error deleting sheikh by uniqueId: $e');
      return {'success': false, 'message': 'فشل حذف الشيخ: $e'};
    }
  }

  // Enhanced search for sheikh with fallbacks (unused - kept for reference)
  /*
  Future<Map<String, dynamic>?> _findSheikhByUniqueId(String uniqueId) async {
    try {
      print('[FirebaseService] Searching for sheikh with uniqueId: $uniqueId');

      // Try multiple search strategies
      final searchStrategies = [
        // Strategy 1: Direct uniqueId match
        () => _searchSheikhByField('uniqueId', uniqueId),
        // Strategy 2: Try code field
        () => _searchSheikhByField('code', uniqueId),
        // Strategy 3: Try sheikhCode field
        () => _searchSheikhByField('sheikhCode', uniqueId),
        // Strategy 4: Try numeric conversion for legacy IDs
        () => _searchSheikhByNumericId(uniqueId),
      ];

      for (int i = 0; i < searchStrategies.length; i++) {
        print('[FirebaseService] Trying search strategy ${i + 1}');
        final result = await searchStrategies[i]();
        if (result != null) {
          print(
            '[FirebaseService] Found sheikh using strategy ${i + 1}: ${result['name']}',
          );
          return result;
        }
      }

      print('[FirebaseService] No sheikh found with any search strategy');
      return null;
    } catch (e) {
      print('[FirebaseService] Error in _findSheikhByUniqueId: $e');
      return null;
    }
  }
  */

  // Search sheikh by specific field
  Future<Map<String, dynamic>?> _searchSheikhByField(
    String field,
    String value,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where(field, isEqualTo: value)
          .where('role', isEqualTo: 'sheikh')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('[FirebaseService] Error searching by $field: $e');
      return null;
    }
  }

  // Search sheikh by numeric ID (for legacy support)
  Future<Map<String, dynamic>?> _searchSheikhByNumericId(
    String uniqueId,
  ) async {
    try {
      // Try to convert to integer for legacy numeric IDs
      final numericId = int.tryParse(uniqueId);
      if (numericId == null) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: numericId)
          .where('role', isEqualTo: 'sheikh')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('[FirebaseService] Error searching by numeric ID: $e');
      return null;
    }
  }

  // Archive lectures by sheikh
  Future<void> archiveLecturesBySheikh(String sheikhUid) async {
    try {
      final lecturesQuery = await _firestore
          .collection('lectures')
          .where('sheikhId', isEqualTo: sheikhUid)
          .get();

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (final doc in lecturesQuery.docs) {
        batch.update(doc.reference, {'status': 'archived', 'archivedAt': now});
      }

      await batch.commit();
    } catch (e) {
      print('Error archiving lectures by sheikh: $e');
    }
  }

  // Get lectures for sheikh
  Stream<List<Map<String, dynamic>>> getLecturesForSheikh(String sheikhUid) {
    return _firestore
        .collection('lectures')
        .where('sheikhId', isEqualTo: sheikhUid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}
