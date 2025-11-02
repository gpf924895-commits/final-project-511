import 'package:sqflite/sqflite.dart';
import 'package:new_project/database/local_sqlite_service.dart';
import 'package:new_project/utils/time.dart';
import 'package:new_project/utils/hash.dart';
import 'package:new_project/utils/uuid.dart';
import 'dart:developer' as developer;

/// Local Repository - SQLite-only implementation
/// Replaces FirebaseService with offline-only local database
class LocalRepository {
  final LocalSQLiteService _dbService = LocalSQLiteService();

  // ==================== User Management ====================

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbService.db;

      // Check if email or username already exists
      final emailCheck = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (emailCheck.isNotEmpty) {
        return {'success': false, 'message': 'الإيميل موجود مسبقاً'};
      }

      final usernameCheck = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (usernameCheck.isNotEmpty) {
        return {'success': false, 'message': 'اسم المستخدم موجود مسبقاً'};
      }

      // Create new user
      final userId = generateUUID();
      final passwordHash = sha256Hex(password);
      final now = nowMillis();

      await db.insert('users', {
        'id': userId,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'is_admin': 0,
        'created_at': now,
        'updated_at': now,
      });

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح',
        'user_id': userId,
      };
    } catch (e) {
      developer.log('Register user error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الحساب: $e'};
    }
  }

  /// User login
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbService.db;
      final passwordHash = sha256Hex(password);

      final results = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
        limit: 1,
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'الإيميل أو كلمة المرور غير صحيحة',
        };
      }

      final user = results.first;

      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'user': {
          'id': user['id'],
          'username': user['username'],
          'email': user['email'],
          'is_admin': (user['is_admin'] as int) == 1,
        },
      };
    } catch (e) {
      developer.log('Login user error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول: $e'};
    }
  }

  /// Admin login
  Future<Map<String, dynamic>> loginAdmin({
    required String username,
    required String password,
  }) async {
    try {
      final db = await _dbService.db;
      final passwordHash = sha256Hex(password);

      // Try username first
      var results = await db.query(
        'users',
        where: 'username = ? AND password_hash = ? AND is_admin = ?',
        whereArgs: [username, passwordHash, 1],
        limit: 1,
      );

      // If not found, try email
      if (results.isEmpty) {
        results = await db.query(
          'users',
          where: 'email = ? AND password_hash = ? AND is_admin = ?',
          whereArgs: [username, passwordHash, 1],
          limit: 1,
        );
      }

      if (results.isEmpty) {
        return {'success': false, 'message': 'بيانات المشرف غير صحيحة'};
      }

      final admin = results.first;

      return {
        'success': true,
        'message': 'مرحباً بك أيها المشرف',
        'admin': {
          'id': admin['id'],
          'username': admin['username'],
          'email': admin['email'],
          'is_admin': true,
        },
      };
    } catch (e) {
      developer.log('Login admin error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل دخول المشرف: $e',
      };
    }
  }

  /// Create admin account
  Future<Map<String, dynamic>> createAdminAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbService.db;

      // Check if email exists
      final emailCheck = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (emailCheck.isNotEmpty) {
        return {'success': false, 'message': 'الإيميل موجود مسبقاً'};
      }

      // Check if username exists
      final usernameCheck = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (usernameCheck.isNotEmpty) {
        return {'success': false, 'message': 'اسم المستخدم موجود مسبقاً'};
      }

      // Create admin user
      final adminId = generateUUID();
      final passwordHash = sha256Hex(password);
      final now = nowMillis();

      await db.insert('users', {
        'id': adminId,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'is_admin': 1,
        'created_at': now,
        'updated_at': now,
      });

      return {
        'success': true,
        'message': 'تم إنشاء حساب المشرف بنجاح',
        'admin_id': adminId,
      };
    } catch (e) {
      developer.log('Create admin error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إنشاء حساب المشرف: $e',
      };
    }
  }

  /// Get all users (non-admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'users',
        where: 'is_admin = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      return results.map((row) {
        final user = Map<String, dynamic>.from(row);
        user['is_admin'] = (user['is_admin'] as int) == 1;
        user.remove('password_hash'); // Never return password hash
        return user;
      }).toList();
    } catch (e) {
      developer.log('Get all users error: $e', name: 'LocalRepository');
      return [];
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      final db = await _dbService.db;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      return true;
    } catch (e) {
      developer.log('Delete user error: $e', name: 'LocalRepository');
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final user = Map<String, dynamic>.from(results.first);
      user['is_admin'] = (user['is_admin'] as int) == 1;
      user.remove('password_hash');
      return user;
    } catch (e) {
      developer.log('Get user profile error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? gender,
    String? birthDate,
    String? profileImageUrl,
  }) async {
    try {
      final db = await _dbService.db;
      final Map<String, dynamic> updateData = {'updated_at': nowMillis()};

      if (name != null) updateData['name'] = name;
      if (gender != null) updateData['gender'] = gender;
      if (birthDate != null) updateData['birth_date'] = birthDate;
      if (profileImageUrl != null)
        updateData['profile_image_url'] = profileImageUrl;

      await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return {'success': true, 'message': 'تم تحديث الملف الشخصي بنجاح'};
    } catch (e) {
      developer.log('Update user profile error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الملف الشخصي: $e',
      };
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changeUserPassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final db = await _dbService.db;

      // Verify old password
      final user = await getUserProfile(userId);
      if (user == null) {
        return {'success': false, 'message': 'المستخدم غير موجود'};
      }

      final results = await db.query(
        'users',
        columns: ['password_hash'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) {
        return {'success': false, 'message': 'المستخدم غير موجود'};
      }

      final storedHash = results.first['password_hash'] as String;
      final oldPasswordHash = sha256Hex(oldPassword);

      if (storedHash != oldPasswordHash) {
        return {'success': false, 'message': 'كلمة المرور القديمة غير صحيحة'};
      }

      // Update password
      final newPasswordHash = sha256Hex(newPassword);
      await db.update(
        'users',
        {'password_hash': newPasswordHash, 'updated_at': nowMillis()},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return {'success': true, 'message': 'تم تغيير كلمة المرور بنجاح'};
    } catch (e) {
      developer.log('Change password error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تغيير كلمة المرور: $e',
      };
    }
  }

  // ==================== Subcategory Management ====================

  /// Get subcategories by section
  Future<List<Map<String, dynamic>>> getSubcategoriesBySection(
    String section,
  ) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'subcategories',
        where: 'section = ?',
        whereArgs: [section],
        orderBy: 'created_at ASC',
      );
      return results;
    } catch (e) {
      developer.log(
        'Get subcategories by section error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Get a single subcategory
  Future<Map<String, dynamic>?> getSubcategory(String id) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'subcategories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isEmpty ? null : results.first;
    } catch (e) {
      developer.log('Get subcategory error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Add subcategory
  Future<Map<String, dynamic>> addSubcategory({
    required String name,
    required String section,
    String? description,
    String? iconName,
  }) async {
    try {
      final db = await _dbService.db;
      final subcatId = generateUUID();
      final now = nowMillis();

      await db.insert('subcategories', {
        'id': subcatId,
        'name': name,
        'section': section,
        'description': description,
        'icon_name': iconName,
        'created_at': now,
      });

      return {
        'success': true,
        'message': 'تم إضافة الفئة الفرعية بنجاح',
        'subcategory_id': subcatId,
      };
    } catch (e) {
      developer.log('Add subcategory error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إضافة الفئة الفرعية: $e',
      };
    }
  }

  /// Update subcategory
  Future<Map<String, dynamic>> updateSubcategory({
    required String id,
    required String name,
    String? description,
    String? iconName,
  }) async {
    try {
      final db = await _dbService.db;
      final Map<String, dynamic> updateData = {'name': name};

      if (description != null) updateData['description'] = description;
      if (iconName != null) updateData['icon_name'] = iconName;

      await db.update(
        'subcategories',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      return {'success': true, 'message': 'تم تحديث الفئة الفرعية بنجاح'};
    } catch (e) {
      developer.log('Update subcategory error: $e', name: 'LocalRepository');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الفئة الفرعية: $e',
      };
    }
  }

  /// Delete subcategory
  Future<bool> deleteSubcategory(String subcategoryId) async {
    try {
      final db = await _dbService.db;
      await db.delete(
        'subcategories',
        where: 'id = ?',
        whereArgs: [subcategoryId],
      );
      return true;
    } catch (e) {
      developer.log('Delete subcategory error: $e', name: 'LocalRepository');
      return false;
    }
  }

  // ==================== Lecture Management ====================

  /// Add lecture
  Future<Map<String, dynamic>> addLecture({
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    try {
      final db = await _dbService.db;
      final lectureId = generateUUID();
      final now = nowMillis();

      await db.insert('lectures', {
        'id': lectureId,
        'title': title,
        'description': description,
        'video_path': videoPath,
        'section': section,
        'subcategory_id': subcategoryId,
        'status': 'draft',
        'isPublished': 0,
        'createdAt': now,
        'updatedAt': now,
      });

      return {
        'success': true,
        'message': 'تم إضافة المحاضرة بنجاح',
        'lecture_id': lectureId,
      };
    } catch (e) {
      developer.log('Add lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة المحاضرة: $e'};
    }
  }

  /// Get all lectures
  Future<List<Map<String, dynamic>>> getAllLectures() async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'status NOT IN (?, ?)',
        whereArgs: ['archived', 'deleted'],
        orderBy: 'createdAt DESC',
      );

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log('Get all lectures error: $e', name: 'LocalRepository');
      return [];
    }
  }

  /// Get lectures by section
  Future<List<Map<String, dynamic>>> getLecturesBySection(
    String section,
  ) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'section = ? AND status NOT IN (?, ?)',
        whereArgs: [section, 'archived', 'deleted'],
        orderBy: 'startTime DESC, createdAt DESC',
      );

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log(
        'Get lectures by section error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Get lectures by subcategory
  Future<List<Map<String, dynamic>>> getLecturesBySubcategory(
    String subcategoryId,
  ) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'subcategory_id = ? AND status NOT IN (?, ?)',
        whereArgs: [subcategoryId, 'archived', 'deleted'],
        orderBy: 'createdAt DESC',
      );

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log(
        'Get lectures by subcategory error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Get a single lecture
  Future<Map<String, dynamic>?> getLecture(String id) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final lecture = Map<String, dynamic>.from(results.first);
      lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
      return lecture;
    } catch (e) {
      developer.log('Get lecture error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Update lecture
  Future<Map<String, dynamic>> updateLecture({
    required String id,
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) async {
    try {
      final db = await _dbService.db;
      final Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'section': section,
        'updatedAt': nowMillis(),
      };

      if (videoPath != null) updateData['video_path'] = videoPath;
      if (subcategoryId != null) updateData['subcategory_id'] = subcategoryId;

      await db.update('lectures', updateData, where: 'id = ?', whereArgs: [id]);

      return {'success': true, 'message': 'تم تحديث المحاضرة بنجاح'};
    } catch (e) {
      developer.log('Update lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث المحاضرة: $e'};
    }
  }

  /// Delete lecture (soft delete - set status to 'deleted')
  Future<bool> deleteLecture(String lectureId) async {
    try {
      final db = await _dbService.db;
      await db.update(
        'lectures',
        {'status': 'deleted', 'updatedAt': nowMillis()},
        where: 'id = ?',
        whereArgs: [lectureId],
      );
      return true;
    } catch (e) {
      developer.log('Delete lecture error: $e', name: 'LocalRepository');
      return false;
    }
  }

  /// Search lectures
  Future<List<Map<String, dynamic>>> searchLectures(String query) async {
    try {
      final db = await _dbService.db;
      final fts5Available = await _dbService.isFts5Available();

      List<Map<String, dynamic>> results;

      if (fts5Available) {
        // Use FTS5 MATCH for full-text search (better performance)
        try {
          // Escape query for FTS5 (basic escaping - wrap in quotes and escape quotes)
          final escapedQuery = query.replaceAll("'", "''");
          final ftsQuery = "'$escapedQuery'";
          // FTS5 MATCH query: join lectures_fts with lectures using rowid
          results = await db.rawQuery('''
            SELECT l.* FROM lectures l
            JOIN lectures_fts fts ON l.rowid = fts.rowid
            WHERE fts MATCH $ftsQuery
              AND l.status NOT IN ('archived', 'deleted')
            ORDER BY l.createdAt DESC
          ''', []);
          developer.log('Using FTS5 search', name: 'LocalRepository');
        } catch (e) {
          developer.log(
            'FTS5 search failed, falling back to LIKE: $e',
            name: 'LocalRepository',
          );
          // Fall back to LIKE if FTS5 query fails
          final searchPattern = '%$query%';
          results = await db.query(
            'lectures',
            where:
                '(title LIKE ? OR description LIKE ?) AND status NOT IN (?, ?)',
            whereArgs: [searchPattern, searchPattern, 'archived', 'deleted'],
            orderBy: 'createdAt DESC',
          );
        }
      } else {
        // Use LIKE search (fallback when FTS5 not available)
        final searchPattern = '%$query%';
        results = await db.query(
          'lectures',
          where:
              '(title LIKE ? OR description LIKE ?) AND status NOT IN (?, ?)',
          whereArgs: [searchPattern, searchPattern, 'archived', 'deleted'],
          orderBy: 'createdAt DESC',
        );
        developer.log(
          'Using LIKE search (FTS5 not available)',
          name: 'LocalRepository',
        );
      }

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log('Search lectures error: $e', name: 'LocalRepository');
      return [];
    }
  }

  // ==================== Sheikh Lecture Management ====================

  /// Add sheikh lecture
  Future<Map<String, dynamic>> addSheikhLecture({
    required String sheikhId,
    required String sheikhName,
    required String section,
    required String categoryId,
    required String categoryName,
    String? subcategoryId,
    String? subcategoryName,
    required String title,
    String? description,
    required int startTime,
    int? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      final db = await _dbService.db;
      final lectureId = generateUUID();
      final now = nowMillis();

      // Extract video path from media if provided
      String? videoPath;
      if (media != null) {
        videoPath =
            media['videoPath']?.toString() ?? media['video_path']?.toString();
      }

      await db.insert('lectures', {
        'id': lectureId,
        'title': title,
        'description': description,
        'video_path': videoPath,
        'section': section,
        'subcategory_id': subcategoryId,
        'sheikhId': sheikhId,
        'sheikhName': sheikhName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryName': subcategoryName,
        'startTime': startTime,
        'endTime': endTime,
        'status': 'draft',
        'isPublished': 0,
        'createdAt': now,
        'updatedAt': now,
      });

      return {
        'success': true,
        'message': 'تم إضافة المحاضرة بنجاح',
        'lecture_id': lectureId,
      };
    } catch (e) {
      developer.log('Add sheikh lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة المحاضرة: $e'};
    }
  }

  /// Get lectures by sheikh
  Future<List<Map<String, dynamic>>> getLecturesBySheikh(
    String sheikhId,
  ) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'sheikhId = ? AND status NOT IN (?, ?)',
        whereArgs: [sheikhId, 'archived', 'deleted'],
        orderBy: 'startTime DESC',
      );

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log(
        'Get lectures by sheikh error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Get lectures by sheikh and category
  Future<List<Map<String, dynamic>>> getLecturesBySheikhAndCategory(
    String sheikhId,
    String categoryId,
  ) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'lectures',
        where: 'sheikhId = ? AND categoryId = ? AND status NOT IN (?, ?)',
        whereArgs: [sheikhId, categoryId, 'archived', 'deleted'],
        orderBy: 'startTime DESC',
      );

      return results.map((row) {
        final lecture = Map<String, dynamic>.from(row);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;
        return lecture;
      }).toList();
    } catch (e) {
      developer.log(
        'Get lectures by sheikh and category error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Update sheikh lecture
  Future<Map<String, dynamic>> updateSheikhLecture({
    required String lectureId,
    required String sheikhId,
    required String title,
    String? description,
    required int startTime,
    int? endTime,
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      final db = await _dbService.db;
      final Map<String, dynamic> updateData = {
        'title': title,
        'startTime': startTime,
        'updatedAt': nowMillis(),
      };

      if (description != null) updateData['description'] = description;
      if (endTime != null) updateData['endTime'] = endTime;

      // Update video path from media if provided
      if (media != null) {
        final videoPath =
            media['videoPath']?.toString() ?? media['video_path']?.toString();
        if (videoPath != null) updateData['video_path'] = videoPath;
      }

      await db.update(
        'lectures',
        updateData,
        where: 'id = ? AND sheikhId = ?',
        whereArgs: [lectureId, sheikhId],
      );

      return {'success': true, 'message': 'تم تحديث المحاضرة بنجاح'};
    } catch (e) {
      developer.log('Update sheikh lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث المحاضرة: $e'};
    }
  }

  /// Archive sheikh lecture
  Future<Map<String, dynamic>> archiveSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    try {
      final db = await _dbService.db;
      await db.update(
        'lectures',
        {'status': 'archived', 'updatedAt': nowMillis()},
        where: 'id = ? AND sheikhId = ?',
        whereArgs: [lectureId, sheikhId],
      );

      return {'success': true, 'message': 'تم أرشفة المحاضرة بنجاح'};
    } catch (e) {
      developer.log(
        'Archive sheikh lecture error: $e',
        name: 'LocalRepository',
      );
      return {'success': false, 'message': 'حدث خطأ أثناء أرشفة المحاضرة: $e'};
    }
  }

  /// Delete sheikh lecture (soft delete)
  Future<Map<String, dynamic>> deleteSheikhLecture({
    required String lectureId,
    required String sheikhId,
  }) async {
    try {
      final db = await _dbService.db;
      await db.update(
        'lectures',
        {'status': 'deleted', 'updatedAt': nowMillis()},
        where: 'id = ? AND sheikhId = ?',
        whereArgs: [lectureId, sheikhId],
      );

      return {'success': true, 'message': 'تم حذف المحاضرة بنجاح'};
    } catch (e) {
      developer.log('Delete sheikh lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء حذف المحاضرة: $e'};
    }
  }

  /// Check for overlapping lectures
  Future<bool> hasOverlappingLectures({
    required String sheikhId,
    required int startTime,
    int? endTime,
    String? excludeLectureId,
  }) async {
    try {
      final db = await _dbService.db;
      String whereClause =
          'sheikhId = ? AND status NOT IN (?, ?) AND ((startTime < ? AND (endTime IS NULL OR endTime > ?)) OR (startTime >= ? AND startTime < ?))';

      List<dynamic> whereArgs = [
        sheikhId,
        'archived',
        'deleted',
        endTime ?? startTime,
        startTime,
        startTime,
        endTime ?? (startTime + 3600000), // Default 1 hour if no endTime
      ];

      if (excludeLectureId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeLectureId);
      }

      final results = await db.query(
        'lectures',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (e) {
      developer.log(
        'Has overlapping lectures error: $e',
        name: 'LocalRepository',
      );
      return false;
    }
  }

  /// Get sheikh lecture statistics
  Future<Map<String, dynamic>> getSheikhLectureStats(String sheikhId) async {
    try {
      final db = await _dbService.db;

      // Total lectures (not archived/deleted)
      final totalResults = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM lectures
        WHERE sheikhId = ? AND status NOT IN ('archived', 'deleted')
      ''',
        [sheikhId],
      );
      final totalLectures = Sqflite.firstIntValue(totalResults) ?? 0;

      // Upcoming today (startTime within today)
      final now = DateTime.now().toUtc();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final todayStartMillis = todayStart.millisecondsSinceEpoch;
      final todayEndMillis = todayEnd.millisecondsSinceEpoch;

      final upcomingResults = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM lectures
        WHERE sheikhId = ? 
        AND status NOT IN ('archived', 'deleted')
        AND startTime >= ? AND startTime < ?
      ''',
        [sheikhId, todayStartMillis, todayEndMillis],
      );
      final upcomingToday = Sqflite.firstIntValue(upcomingResults) ?? 0;

      // Last updated
      final lastUpdatedResults = await db.rawQuery(
        '''
        SELECT MAX(updatedAt) as lastUpdated FROM lectures
        WHERE sheikhId = ? AND status NOT IN ('archived', 'deleted')
      ''',
        [sheikhId],
      );
      final lastUpdated = Sqflite.firstIntValue(lastUpdatedResults);

      return {
        'totalLectures': totalLectures,
        'upcomingToday': upcomingToday,
        'lastUpdated': lastUpdated,
      };
    } catch (e) {
      developer.log('Get sheikh stats error: $e', name: 'LocalRepository');
      return {'totalLectures': 0, 'upcomingToday': 0, 'lastUpdated': null};
    }
  }

  /// Initialize default subcategories (if empty)
  Future<void> initializeDefaultSubcategoriesIfEmpty() async {
    return initializeDefaultSubcategories();
  }

  /// Initialize default subcategories
  Future<void> initializeDefaultSubcategories() async {
    try {
      final db = await _dbService.db;

      // Check if subcategories already exist
      final existing = await db.query('subcategories', limit: 1);
      if (existing.isNotEmpty) {
        developer.log(
          'Subcategories already initialized',
          name: 'LocalRepository',
        );
        return;
      }

      final now = nowMillis();
      final sections = ['الفقه', 'الحديث', 'التفسير', 'السيرة'];

      for (final section in sections) {
        final subcatId = generateUUID();
        await db.insert('subcategories', {
          'id': subcatId,
          'name': section,
          'section': section,
          'description': null,
          'icon_name': null,
          'created_at': now,
        });
      }

      developer.log(
        'Default subcategories initialized',
        name: 'LocalRepository',
      );
    } catch (e) {
      developer.log(
        'Initialize subcategories error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Ensure default admin account exists
  Future<void> ensureDefaultAdmin() async {
    try {
      final db = await _dbService.db;
      final adminCheck = await db.query(
        'users',
        where: 'is_admin = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (adminCheck.isEmpty) {
        await createAdminAccount(
          username: 'admin',
          email: 'admin@admin.com',
          password: 'admin123',
        );
        developer.log('Default admin account created', name: 'LocalRepository');
      }
    } catch (e) {
      developer.log('Ensure default admin error: $e', name: 'LocalRepository');
    }
  }

  /// Get user by uniqueId (for sheikh authentication)
  Future<Map<String, dynamic>?> getUserByUniqueId(
    String uniqueId, {
    String role = 'sheikh',
  }) async {
    try {
      final db = await _dbService.db;
      final results = await db.query(
        'users',
        where: 'uniqueId = ?',
        whereArgs: [uniqueId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final user = Map<String, dynamic>.from(results.first);
      user['is_admin'] = (user['is_admin'] as int) == 1;
      user['uid'] = user['id']; // Add uid for compatibility
      user.remove('password_hash');
      return user;
    } catch (e) {
      developer.log('Get user by uniqueId error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Archive all lectures by a sheikh
  Future<void> archiveLecturesBySheikh(String sheikhId) async {
    try {
      final db = await _dbService.db;
      final now = nowMillis();
      await db.update(
        'lectures',
        {'status': 'archived', 'updatedAt': now},
        where: 'sheikhId = ?',
        whereArgs: [sheikhId],
      );
    } catch (e) {
      developer.log(
        'Archive lectures by sheikh error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Create a sheikh in the sheikhs table
  Future<Map<String, dynamic>> createSheikh({
    required String name,
    String? email,
    String? phone,
    String? uniqueId,
    String? category,
  }) async {
    try {
      final db = await _dbService.db;

      // Check uniqueId uniqueness if provided
      if (uniqueId != null && uniqueId.isNotEmpty) {
        final existing = await db.query(
          'sheikhs',
          where: 'uniqueId = ? AND isDeleted = 0',
          whereArgs: [uniqueId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          return {'success': false, 'message': 'UniqueId already exists'};
        }
      }

      final now = DateTime.now().toIso8601String();
      final insertedId = await db.insert('sheikhs', {
        'uniqueId': uniqueId,
        'name': name,
        'email': email,
        'phone': phone,
        'category': category,
        'createdAt': now,
        'updatedAt': now,
        'isDeleted': 0,
      });

      return {
        'success': true,
        'id': insertedId,
        'message': 'Sheikh created',
        'sheikhId': uniqueId,
      };
    } catch (e) {
      developer.log('Create sheikh error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الشيخ: $e'};
    }
  }

  /// Count sheikhs
  Future<int> countSheikhs() async {
    try {
      final db = await _dbService.db;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sheikhs WHERE isDeleted = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Count sheikhs error: $e', name: 'LocalRepository');
      return 0;
    }
  }

  /// Update user uniqueId and role (for sheikh accounts)
  Future<void> updateUserRoleAndUniqueId({
    required String userId,
    String? uniqueId,
    String? role,
    String? name,
  }) async {
    try {
      final db = await _dbService.db;
      final updates = <String, dynamic>{};
      if (uniqueId != null) updates['uniqueId'] = uniqueId;
      if (role != null) updates['role'] = role;
      if (name != null) updates['name'] = name;
      if (updates.isNotEmpty) {
        updates['updated_at'] = nowMillis();
        await db.update('users', updates, where: 'id = ?', whereArgs: [userId]);
      }
    } catch (e) {
      developer.log(
        'Update user role/uniqueId error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Get table counts for logging
  Future<Map<String, int>> getTableCounts() async {
    try {
      return {
        'users': await _dbService.getRowCount('users'),
        'subcategories': await _dbService.getRowCount('subcategories'),
        'lectures': await _dbService.getRowCount('lectures'),
        'sheikhs': await _dbService.getRowCount('sheikhs'),
      };
    } catch (e) {
      developer.log('Get table counts error: $e', name: 'LocalRepository');
      return {'users': 0, 'subcategories': 0, 'lectures': 0, 'sheikhs': 0};
    }
  }
}
