import 'package:sqflite/sqflite.dart';
import 'package:new_project/database/app_database.dart';
import 'package:new_project/utils/time.dart';
import 'package:new_project/utils/hash.dart';
import 'package:new_project/utils/uuid.dart';
import 'package:new_project/utils/date_converter.dart';
import 'dart:developer' as developer;

/// Local Repository - SQLite-only implementation
/// Replaces FirebaseService with offline-only local database
/// Uses AppDatabase with defensive retry for crash-proof operations
class LocalRepository {
  final AppDatabase _dbService = AppDatabase();

  /// Helper to execute database operations with defensive retry
  Future<T> _withRetry<T>(
    Future<T> Function(Database) operation,
    String operationName,
  ) async {
    return await _dbService.withRetry(() async {
      final db = await _dbService.database;
      return await operation(db);
    }, operationName: operationName);
  }

  // ==================== User Management ====================

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      return await _withRetry((db) async {
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
      }, 'registerUser');
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
      return await _withRetry((db) async {
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
      }, 'loginUser');
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
      return await _withRetry((db) async {
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
      }, 'loginAdmin');
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
      return await _withRetry((db) async {
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
      }, 'createAdminAccount');
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
      return await _withRetry((db) async {
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
      }, 'getAllUsers');
    } catch (e) {
      developer.log('Get all users error: $e', name: 'LocalRepository');
      return [];
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      return await _withRetry((db) async {
        await db.delete('users', where: 'id = ?', whereArgs: [userId]);
        return true;
      }, 'deleteUser');
    } catch (e) {
      developer.log('Delete user error: $e', name: 'LocalRepository');
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _withRetry((db) async {
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
      }, 'getUserProfile');
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
      return await _withRetry((db) async {
        final Map<String, dynamic> updateData = {'updated_at': nowMillis()};

        if (name != null) updateData['name'] = name;
        if (gender != null) updateData['gender'] = gender;
        if (birthDate != null) updateData['birth_date'] = birthDate;
        if (profileImageUrl != null) {
          updateData['profile_image_url'] = profileImageUrl;
        }

        await db.update(
          'users',
          updateData,
          where: 'id = ?',
          whereArgs: [userId],
        );

        return {'success': true, 'message': 'تم تحديث الملف الشخصي بنجاح'};
      }, 'updateUserProfile');
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
      // Verify old password
      final user = await getUserProfile(userId);
      if (user == null) {
        return {'success': false, 'message': 'المستخدم غير موجود'};
      }

      return await _withRetry((db) async {
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
      }, 'changeUserPassword');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'subcategories',
          where: 'section = ?',
          whereArgs: [section],
          orderBy: 'created_at ASC',
        );
        return results;
      }, 'getSubcategoriesBySection');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'subcategories',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        return results.isEmpty ? null : results.first;
      }, 'getSubcategory');
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
      return await _withRetry((db) async {
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
      }, 'addSubcategory');
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
      return await _withRetry((db) async {
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
      }, 'updateSubcategory');
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
      return await _withRetry((db) async {
        await db.delete(
          'subcategories',
          where: 'id = ?',
          whereArgs: [subcategoryId],
        );
        return true;
      }, 'deleteSubcategory');
    } catch (e) {
      developer.log('Delete subcategory error: $e', name: 'LocalRepository');
      return false;
    }
  }

  // ==================== Category Management ====================

  /// Get categories by section
  /// Returns list of categories filtered by section_id and isDeleted=0, ordered by sortOrder then id
  Future<List<Map<String, dynamic>>> getCategoriesBySection(
    String sectionId,
  ) async {
    try {
      return await _withRetry((db) async {
        final normalizedSection = sectionId.trim();
        if (normalizedSection.isEmpty) {
          developer.log(
            'getCategoriesBySection: empty sectionId',
            name: 'LocalRepository',
          );
          return [];
        }

        final results = await db.query(
          'categories',
          where: 'section_id = ? AND isDeleted = ?',
          whereArgs: [normalizedSection, 0],
          orderBy: 'sortOrder ASC, id ASC',
        );

        final dbPath = await _dbService.getDatabasePath();
        developer.log(
          'getCategoriesBySection: found ${results.length} categories for section=$normalizedSection, DB=$dbPath',
          name: 'LocalRepository',
        );

        return results;
      }, 'getCategoriesBySection');
    } catch (e) {
      developer.log(
        'Get categories by section error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Add a new category
  /// Returns map with success, message, and categoryId
  Future<Map<String, dynamic>> addCategory({
    required String sectionId,
    required String name,
    String? description,
    int order = 0,
  }) async {
    try {
      return await _withRetry((db) async {
        final normalizedName = name.trim();
        if (normalizedName.isEmpty) {
          throw Exception('Category name cannot be empty');
        }

        final normalizedSection = sectionId.trim();
        if (normalizedSection.isEmpty) {
          throw Exception('Section ID cannot be empty');
        }

        final categoryId = generateUUID();
        final now = nowMillis();

        final normalizedDescription = (description ?? '').trim();
        final rowsAffected = await db.insert('categories', {
          'id': categoryId,
          'section_id': normalizedSection,
          'name': normalizedName,
          'description': normalizedDescription.isEmpty
              ? null
              : normalizedDescription,
          'sortOrder': order,
          'isDeleted': 0,
          'createdAt': now,
          'updatedAt': now,
        });

        if (rowsAffected > 0) {
          final dbPath = await _dbService.getDatabasePath();
          developer.log(
            'addCategory: inserted categoryId=$categoryId, section=$normalizedSection, DB=$dbPath',
            name: 'LocalRepository',
          );
          return {
            'success': true,
            'message': 'تم إضافة الفئة بنجاح',
            'categoryId': categoryId,
          };
        } else {
          return {'success': false, 'message': 'فشل إضافة الفئة'};
        }
      }, 'addCategory');
    } catch (e) {
      developer.log('Add category error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة الفئة: $e'};
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
      return await _withRetry((db) async {
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
      }, 'addLecture');
    } catch (e) {
      developer.log('Add lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة المحاضرة: $e'};
    }
  }

  /// Get all lectures
  Future<List<Map<String, dynamic>>> getAllLectures() async {
    try {
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'status NOT IN (?, ?)',
          whereArgs: ['archived', 'deleted'],
          orderBy: 'createdAt DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getAllLectures');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'section = ? AND status NOT IN (?, ?)',
          whereArgs: [section, 'archived', 'deleted'],
          orderBy: 'startTime DESC, createdAt DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getLecturesBySection');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'subcategory_id = ? AND status NOT IN (?, ?)',
          whereArgs: [subcategoryId, 'archived', 'deleted'],
          orderBy: 'createdAt DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getLecturesBySubcategory');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (results.isEmpty) return null;

        final lecture = Map<String, dynamic>.from(results.first);
        lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

        // Convert date fields safely: int (epoch ms) -> DateTime
        lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
        lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
        lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
        lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
        lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
        lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

        return lecture;
      }, 'getLecture');
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
      return await _withRetry((db) async {
        final Map<String, dynamic> updateData = {
          'title': title,
          'description': description,
          'section': section,
          'updatedAt': nowMillis(),
        };

        if (videoPath != null) updateData['video_path'] = videoPath;
        if (subcategoryId != null) updateData['subcategory_id'] = subcategoryId;

        await db.update(
          'lectures',
          updateData,
          where: 'id = ?',
          whereArgs: [id],
        );

        return {'success': true, 'message': 'تم تحديث المحاضرة بنجاح'};
      }, 'updateLecture');
    } catch (e) {
      developer.log('Update lecture error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث المحاضرة: $e'};
    }
  }

  /// Delete lecture (soft delete - set status to 'deleted')
  Future<bool> deleteLecture(String lectureId) async {
    try {
      return await _withRetry((db) async {
        await db.update(
          'lectures',
          {'status': 'deleted', 'updatedAt': nowMillis()},
          where: 'id = ?',
          whereArgs: [lectureId],
        );
        return true;
      }, 'deleteLecture');
    } catch (e) {
      developer.log('Delete lecture error: $e', name: 'LocalRepository');
      return false;
    }
  }

  /// Search lectures
  Future<List<Map<String, dynamic>>> searchLectures(String query) async {
    try {
      final fts5Available = await _dbService.isFts5Available();
      return await _withRetry((db) async {
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

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'searchLectures');
    } catch (e) {
      developer.log('Search lectures error: $e', name: 'LocalRepository');
      return [];
    }
  }

  // ==================== Sheikh Lecture Management ====================

  /// Add sheikh lecture
  /// startTime and endTime can be DateTime, int (epoch ms), Timestamp, or String (ISO)
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
    required dynamic startTime, // DateTime, int, Timestamp, String
    dynamic endTime, // DateTime, int, Timestamp, String, null
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      return await _withRetry((db) async {
        final lectureId = generateUUID();
        final now = nowMillis();

        // Extract video path from media if provided
        String? videoPath;
        if (media != null) {
          videoPath =
              media['videoPath']?.toString() ?? media['video_path']?.toString();
        }

        // Convert dates to epoch milliseconds for SQLite storage
        final startTimeMs = safeDateToEpochMsFromDynamic(startTime);
        if (startTimeMs == null) {
          throw Exception('startTime is required and must be a valid date');
        }
        final endTimeMs = safeDateToEpochMsFromDynamic(endTime);

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
          'startTime': startTimeMs,
          'endTime': endTimeMs,
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
      }, 'addSheikhLecture');
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
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'sheikhId = ? AND status NOT IN (?, ?)',
          whereArgs: [sheikhId, 'archived', 'deleted'],
          orderBy: 'startTime DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getLecturesBySheikh');
    } catch (e) {
      developer.log(
        'Get lectures by sheikh error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Get lectures by category (for any sheikh)
  /// Returns lectures filtered by categoryId and isDeleted=0, ordered by startTime
  Future<List<Map<String, dynamic>>> getLecturesByCategory(
    String categoryId,
  ) async {
    try {
      return await _withRetry((db) async {
        final normalizedCategoryId = categoryId.trim();
        if (normalizedCategoryId.isEmpty) {
          return [];
        }

        final results = await db.query(
          'lectures',
          where: 'categoryId = ? AND status NOT IN (?, ?)',
          whereArgs: [normalizedCategoryId, 'archived', 'deleted'],
          orderBy: 'startTime DESC, createdAt DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getLecturesByCategory');
    } catch (e) {
      developer.log(
        'Get lectures by category error: $e',
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
      return await _withRetry((db) async {
        final results = await db.query(
          'lectures',
          where: 'sheikhId = ? AND categoryId = ? AND status NOT IN (?, ?)',
          whereArgs: [sheikhId, categoryId, 'archived', 'deleted'],
          orderBy: 'startTime DESC',
        );

        return results.map((row) {
          final lecture = Map<String, dynamic>.from(row);
          lecture['isPublished'] = (lecture['isPublished'] as int) == 1;

          // Convert date fields safely: int (epoch ms) -> DateTime
          lecture['startTime'] = safeDateFromDynamic(lecture['startTime']);
          lecture['endTime'] = safeDateFromDynamic(lecture['endTime']);
          lecture['createdAt'] = safeDateFromDynamic(lecture['createdAt']);
          lecture['updatedAt'] = safeDateFromDynamic(lecture['updatedAt']);
          lecture['archivedAt'] = safeDateFromDynamic(lecture['archivedAt']);
          lecture['deletedAt'] = safeDateFromDynamic(lecture['deletedAt']);

          return lecture;
        }).toList();
      }, 'getLecturesBySheikhAndCategory');
    } catch (e) {
      developer.log(
        'Get lectures by sheikh and category error: $e',
        name: 'LocalRepository',
      );
      return [];
    }
  }

  /// Update sheikh lecture
  /// startTime and endTime can be DateTime, int (epoch ms), Timestamp, or String (ISO)
  Future<Map<String, dynamic>> updateSheikhLecture({
    required String lectureId,
    required String sheikhId,
    required String title,
    String? description,
    required dynamic startTime, // DateTime, int, Timestamp, String
    dynamic endTime, // DateTime, int, Timestamp, String, null
    Map<String, dynamic>? location,
    Map<String, dynamic>? media,
  }) async {
    try {
      return await _withRetry((db) async {
        // Convert dates to epoch milliseconds for SQLite storage
        final startTimeMs = safeDateToEpochMsFromDynamic(startTime);
        if (startTimeMs == null) {
          throw Exception('startTime is required and must be a valid date');
        }
        final endTimeMs = safeDateToEpochMsFromDynamic(endTime);

        final Map<String, dynamic> updateData = {
          'title': title,
          'startTime': startTimeMs,
          'updatedAt': nowMillis(),
        };

        if (description != null) updateData['description'] = description;
        if (endTimeMs != null) updateData['endTime'] = endTimeMs;

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
      }, 'updateSheikhLecture');
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
      return await _withRetry((db) async {
        await db.update(
          'lectures',
          {'status': 'archived', 'updatedAt': nowMillis()},
          where: 'id = ? AND sheikhId = ?',
          whereArgs: [lectureId, sheikhId],
        );

        return {'success': true, 'message': 'تم أرشفة المحاضرة بنجاح'};
      }, 'archiveSheikhLecture');
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
      return await _withRetry((db) async {
        await db.update(
          'lectures',
          {'status': 'deleted', 'updatedAt': nowMillis()},
          where: 'id = ? AND sheikhId = ?',
          whereArgs: [lectureId, sheikhId],
        );

        return {'success': true, 'message': 'تم حذف المحاضرة بنجاح'};
      }, 'deleteSheikhLecture');
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
      return await _withRetry((db) async {
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
      }, 'hasOverlappingLectures');
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
      return await _withRetry((db) async {
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
      }, 'getSheikhLectureStats');
    } catch (e) {
      developer.log('Get sheikh stats error: $e', name: 'LocalRepository');
      return {'totalLectures': 0, 'upcomingToday': 0, 'lastUpdated': null};
    }
  }

  /// Initialize default subcategories
  Future<void> initializeDefaultSubcategories() async {
    try {
      await _withRetry((db) async {
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
      }, 'initializeDefaultSubcategories');
    } catch (e) {
      developer.log(
        'Initialize subcategories error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Initialize default subcategories (if empty) - alias for compatibility
  Future<void> initializeDefaultSubcategoriesIfEmpty() async {
    return initializeDefaultSubcategories();
  }

  /// Ensure default admin account exists
  Future<void> ensureDefaultAdmin() async {
    try {
      await _withRetry((db) async {
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
          developer.log(
            'Default admin account created',
            name: 'LocalRepository',
          );
        }
      }, 'ensureDefaultAdmin');
    } catch (e) {
      developer.log('Ensure default admin error: $e', name: 'LocalRepository');
    }
  }

  /// Login sheikh using uniqueId and password - uses sheikhs table only
  /// Returns sheikh data if authentication succeeds, null otherwise
  Future<Map<String, dynamic>?> loginSheikh(
    String uniqueId,
    String password,
  ) async {
    try {
      return await _withRetry((db) async {
        // Normalize inputs
        final uid = uniqueId.trim().replaceAll(RegExp(r'[^0-9]'), '');
        final pwd = password.trim();

        if (uid.isEmpty || uid.length != 8) {
          return null;
        }
        if (pwd.isEmpty) {
          return null;
        }

        // Hash the password
        final passwordHash = sha256Hex(pwd);

        // Query sheikhs table for matching uniqueId and passwordHash
        final results = await db.query(
          'sheikhs',
          where: 'uniqueId = ? AND passwordHash = ? AND isDeleted = 0',
          whereArgs: [uid, passwordHash],
          limit: 1,
        );

        if (results.isEmpty) {
          return null;
        }

        final sheikh = Map<String, dynamic>.from(results.first);
        // Map sheikh data to expected format (don't expose passwordHash)
        return {
          'id': sheikh['id']?.toString() ?? uid,
          'uid': sheikh['id']?.toString() ?? uid,
          'uniqueId': sheikh['uniqueId'],
          'name': sheikh['name'],
          'email': sheikh['email'],
          'role': 'sheikh',
          'category': sheikh['category'],
          'phone': sheikh['phone'],
        };
      }, 'loginSheikh');
    } catch (e) {
      developer.log('Login sheikh error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Get sheikh by uniqueId - uses sheikhs table only (single source of truth)
  Future<Map<String, dynamic>?> getSheikhByUniqueId(String uniqueId) async {
    try {
      return await _withRetry((db) async {
        // Normalize uniqueId
        final uid = uniqueId.trim().replaceAll(RegExp(r'[^0-9]'), '');
        if (uid.isEmpty || uid.length != 8) {
          return null;
        }

        final results = await db.query(
          'sheikhs',
          where: 'uniqueId = ? AND isDeleted = 0',
          whereArgs: [uid],
          limit: 1,
        );

        if (results.isEmpty) {
          return null;
        }

        final sheikh = Map<String, dynamic>.from(results.first);
        // Map sheikh data to expected format (don't expose passwordHash)
        return {
          'id': sheikh['id']?.toString() ?? uid,
          'uid': sheikh['id']?.toString() ?? uid,
          'uniqueId': sheikh['uniqueId'],
          'name': sheikh['name'],
          'email': sheikh['email'],
          'role': 'sheikh',
          'category': sheikh['category'],
          'phone': sheikh['phone'],
        };
      }, 'getSheikhByUniqueId');
    } catch (e) {
      developer.log(
        'Get sheikh by uniqueId error: $e',
        name: 'LocalRepository',
      );
      return null;
    }
  }

  /// Get user by uniqueId - for non-sheikh users only
  /// For sheikhs, use getSheikhByUniqueId instead
  Future<Map<String, dynamic>?> getUserByUniqueId(
    String uniqueId, {
    String role = 'sheikh',
  }) async {
    // For sheikh role, use sheikhs table exclusively
    if (role == 'sheikh') {
      return await getSheikhByUniqueId(uniqueId);
    }

    // For other roles, use users table
    try {
      return await _withRetry((db) async {
        final userResults = await db.query(
          'users',
          where: 'uniqueId = ? AND role = ?',
          whereArgs: [uniqueId, role],
          limit: 1,
        );

        if (userResults.isNotEmpty) {
          final user = Map<String, dynamic>.from(userResults.first);
          user['is_admin'] = (user['is_admin'] as int) == 1;
          user['uid'] = user['id']; // Add uid for compatibility
          user.remove('password_hash');
          return user;
        }

        return null;
      }, 'getUserByUniqueId');
    } catch (e) {
      developer.log('Get user by uniqueId error: $e', name: 'LocalRepository');
      return null;
    }
  }

  /// Archive all lectures by a sheikh
  Future<void> archiveLecturesBySheikh(String sheikhId) async {
    try {
      await _withRetry((db) async {
        final now = nowMillis();
        await db.update(
          'lectures',
          {'status': 'archived', 'updatedAt': now},
          where: 'sheikhId = ?',
          whereArgs: [sheikhId],
        );
      }, 'archiveLecturesBySheikh');
    } catch (e) {
      developer.log(
        'Archive lectures by sheikh error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Delete sheikh by unique_sheikh_id (8 digits)
  /// Soft-deletes the sheikh (sets isDeleted = 1) and archives related lectures
  Future<Map<String, dynamic>> deleteSheikhByUniqueId(String uniqueId) async {
    try {
      return await _withRetry((db) async {
        // Normalize uniqueId input (exactly 8 digits)
        final normalized = uniqueId.trim().replaceAll(RegExp(r'[^0-9]'), '');
        if (normalized.isEmpty || normalized.length != 8) {
          return {
            'success': false,
            'message': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط',
          };
        }

        // Check if sheikh exists
        final results = await db.query(
          'sheikhs',
          where: 'uniqueId = ? AND isDeleted = 0',
          whereArgs: [normalized],
          limit: 1,
        );

        if (results.isEmpty) {
          return {'success': false, 'message': 'الشيخ غير موجود'};
        }

        final sheikh = results.first;
        final sheikhId = sheikh['id']?.toString();

        // Archive all lectures by this sheikh
        if (sheikhId != null) {
          await archiveLecturesBySheikh(sheikhId);
        }

        // Soft-delete the sheikh
        final now = nowMillis();
        await db.update(
          'sheikhs',
          {'isDeleted': 1, 'updatedAt': now},
          where: 'uniqueId = ?',
          whereArgs: [normalized],
        );

        return {'success': true, 'message': 'تم حذف الشيخ بنجاح'};
      }, 'deleteSheikhByUniqueId');
    } catch (e) {
      developer.log(
        'Delete sheikh by uniqueId error: $e',
        name: 'LocalRepository',
      );
      return {'success': false, 'message': 'حدث خطأ أثناء حذف الشيخ: $e'};
    }
  }

  /// Create a sheikh in the sheikhs table
  /// uniqueId must be TEXT and exactly 8 digits
  /// password is optional but will be hashed if provided
  Future<Map<String, dynamic>> createSheikh({
    required String name,
    String? email,
    String? phone,
    String? uniqueId,
    String? category,
    String? password,
  }) async {
    try {
      return await _withRetry((db) async {
        // Normalize uniqueId input (null-safe)
        final uidInput = (uniqueId ?? '').trim();

        // Validate uniqueId: must be TEXT, exactly 8 digits
        if (uidInput.isNotEmpty) {
          final normalized = uidInput.replaceAll(RegExp(r'[^0-9]'), '');
          if (normalized.isEmpty) {
            return {
              'success': false,
              'message': 'رقم الشيخ يجب أن يحتوي على أرقام فقط',
            };
          }
          if (normalized.length != 8) {
            return {
              'success': false,
              'message': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط',
            };
          }
          // Use normalized 8-digit value
          uniqueId = normalized;

          // Check uniqueId uniqueness
          final existing = await db.query(
            'sheikhs',
            where: 'uniqueId = ? AND isDeleted = 0',
            whereArgs: [uniqueId],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            return {'success': false, 'message': 'رقم الشيخ موجود مسبقاً'};
          }
        }

        // Normalize password (null-safe)
        final pwdInput = (password ?? '').trim();
        final passwordHash = pwdInput.isNotEmpty ? sha256Hex(pwdInput) : null;

        final now = DateTime.now().millisecondsSinceEpoch;
        final insertedId = await db.insert('sheikhs', {
          'uniqueId': uniqueId ?? '', // TEXT type - preserves leading zeros
          'name': name,
          'email': email,
          'phone': phone,
          'category': category,
          'passwordHash': passwordHash,
          'createdAt': now,
          'updatedAt': now,
          'isDeleted': 0,
        });

        return {
          'success': true,
          'id': insertedId,
          'message': 'تم إنشاء الشيخ بنجاح',
          'sheikhId': uniqueId,
        };
      }, 'createSheikh');
    } catch (e) {
      developer.log('Create sheikh error: $e', name: 'LocalRepository');
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الشيخ: $e'};
    }
  }

  /// Count sheikhs
  Future<int> countSheikhs() async {
    try {
      return await _withRetry((db) async {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM sheikhs WHERE isDeleted = 0',
        );
        return Sqflite.firstIntValue(result) ?? 0;
      }, 'countSheikhs');
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
      await _withRetry((db) async {
        final updates = <String, dynamic>{};
        // Normalize uniqueId input (null-safe)
        final uidInput = (uniqueId ?? '').trim();
        if (uidInput.isNotEmpty) {
          // Validate uniqueId: must be TEXT, exactly 8 digits
          final normalized = uidInput.replaceAll(RegExp(r'[^0-9]'), '');
          if (normalized.isNotEmpty && normalized.length == 8) {
            updates['uniqueId'] = normalized; // Use normalized value
          }
        }
        if (role != null) updates['role'] = role;
        if (name != null) updates['name'] = name;
        if (updates.isNotEmpty) {
          updates['updated_at'] = nowMillis();
          await db.update(
            'users',
            updates,
            where: 'id = ?',
            whereArgs: [userId],
          );
        }
      }, 'updateUserRoleAndUniqueId');
    } catch (e) {
      developer.log(
        'Update user role/uniqueId error: $e',
        name: 'LocalRepository',
      );
    }
  }

  /// Get all sheikhs (non-deleted only)
  Future<List<Map<String, dynamic>>> getAllSheikhs({
    String? search,
    String? category,
    int? limit,
  }) async {
    try {
      return await _withRetry((db) async {
        var query = 'SELECT * FROM sheikhs WHERE isDeleted = 0';
        final whereArgs = <dynamic>[];

        // Normalize category input (null-safe)
        final catInput = (category ?? '').trim();
        if (catInput.isNotEmpty) {
          query += ' AND category = ?';
          whereArgs.add(catInput);
        }

        // Normalize search input (null-safe)
        final searchInput = (search ?? '').trim();
        if (searchInput.isNotEmpty) {
          query += ' AND (name LIKE ? OR email LIKE ? OR uniqueId LIKE ?)';
          final searchTerm = '%$searchInput%';
          whereArgs.add(searchTerm);
          whereArgs.add(searchTerm);
          whereArgs.add(searchTerm);
        }

        query += ' ORDER BY createdAt DESC';

        if (limit != null && limit > 0) {
          query += ' LIMIT ?';
          whereArgs.add(limit);
        }

        final results = await db.rawQuery(query, whereArgs);
        return results.map((row) {
          final sheikh = Map<String, dynamic>.from(row);
          sheikh['sheikhId'] = sheikh['uniqueId']; // Alias for compatibility
          return sheikh;
        }).toList();
      }, 'getAllSheikhs');
    } catch (e) {
      developer.log('Get all sheikhs error: $e', name: 'LocalRepository');
      return [];
    }
  }

  /// Get table counts for logging
  Future<Map<String, int>> getTableCounts() async {
    try {
      return await _withRetry((db) async {
        final usersCount =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM users'),
            ) ??
            0;
        final subcategoriesCount =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM subcategories'),
            ) ??
            0;
        final lecturesCount =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM lectures'),
            ) ??
            0;
        final sheikhsCount =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM sheikhs WHERE isDeleted = 0',
              ),
            ) ??
            0;
        return {
          'users': usersCount,
          'subcategories': subcategoriesCount,
          'lectures': lecturesCount,
          'sheikhs': sheikhsCount,
        };
      }, 'getTableCounts');
    } catch (e) {
      developer.log('Get table counts error: $e', name: 'LocalRepository');
      return {'users': 0, 'subcategories': 0, 'lectures': 0, 'sheikhs': 0};
    }
  }
}
