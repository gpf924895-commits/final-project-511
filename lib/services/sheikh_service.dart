import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'dart:async';

class SheikhServiceException implements Exception {
  final String message;

  SheikhServiceException(this.message);

  @override
  String toString() => message;
}

class SheikhQueryResult {
  final List<Map<String, dynamic>> items;
  final bool fallbackMode;
  final String? indexCreateUrl;
  final String? errorMessage;

  SheikhQueryResult({
    required this.items,
    this.fallbackMode = false,
    this.indexCreateUrl,
    this.errorMessage,
  });
}

class SheikhService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _timeout = Duration(seconds: 8);

  /// Preview next Sheikh ID (non-blocking read, no transaction)
  /// Used for display only - actual allocation happens on submit
  Future<String> previewNextSheikhId() async {
    try {
      final counterDoc = await _firestore
          .collection('meta')
          .doc('counters')
          .get()
          .timeout(_timeout);

      int currentCounter = 0;
      if (counterDoc.exists && counterDoc.data()?['sheikhCounter'] != null) {
        final data = counterDoc.data();
        if (data != null) {
          currentCounter = (data['sheikhCounter'] as int?) ?? 0;
        }
      }

      final nextCounter = currentCounter + 1;
      final previewId = nextCounter.toString().padLeft(8, '0');

      developer.log(
        'Preview Sheikh ID: $previewId (current counter: $currentCounter)',
        name: 'SheikhService',
      );

      return previewId;
    } on TimeoutException {
      developer.log(
        'Timeout fetching preview ID',
        name: 'SheikhService',
        error: 'Timeout',
      );
      throw SheikhServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log(
        'Error fetching preview Sheikh ID',
        name: 'SheikhService',
        error: e,
      );
      // Return fallback preview - actual ID will be allocated on submit
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 100000000).toString().padLeft(8, '0');
    }
  }

  /// Allocate next Sheikh ID atomically (transaction-based)
  /// Called ONLY on submit to ensure sequential IDs without duplicates
  Future<String> allocateNextSheikhId() async {
    try {
      final counterRef = _firestore.collection('meta').doc('counters');

      return await _firestore
          .runTransaction<String>((transaction) async {
            final counterDoc = await transaction.get(counterRef);

            int currentCounter = 0;
            if (counterDoc.exists &&
                counterDoc.data()?['sheikhCounter'] != null) {
              final data = counterDoc.data();
              if (data != null) {
                currentCounter = (data['sheikhCounter'] as int?) ?? 0;
              }
            }

            final nextCounter = currentCounter + 1;
            final sheikhId = nextCounter.toString().padLeft(8, '0');

            // Update counter atomically
            transaction.set(counterRef, {
              'sheikhCounter': nextCounter,
            }, SetOptions(merge: true));

            developer.log(
              'Allocated Sheikh ID: $sheikhId (counter: $nextCounter)',
              name: 'SheikhService',
            );

            return sheikhId;
          })
          .timeout(_timeout);
    } on TimeoutException {
      developer.log(
        'Timeout allocating Sheikh ID',
        name: 'SheikhService',
        error: 'Timeout',
      );
      throw SheikhServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw SheikhServiceException('ليس لديك صلاحية لإنشاء أرقام الشيوخ');
      } else if (e.code == 'unavailable') {
        throw SheikhServiceException('الخدمة غير متاحة. حاول مجددًا لاحقاً.');
      } else if (e.code == 'deadline-exceeded') {
        throw SheikhServiceException(
          'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
        );
      }
      developer.log(
        'Firebase error allocating Sheikh ID',
        name: 'SheikhService',
        error: e,
      );
      throw SheikhServiceException('فشل تخصيص رقم الشيخ: ${e.message}');
    } catch (e) {
      developer.log(
        'Error allocating Sheikh ID',
        name: 'SheikhService',
        error: e,
      );
      throw SheikhServiceException('حدث خطأ أثناء تخصيص رقم الشيخ: $e');
    }
  }

  /// Verify user is admin (fast check)
  /// Handles both Firebase Auth-based admins and database-based admins
  Future<bool> isAdmin(String uid) async {
    try {
      // Check if this is a database-based admin (starts with 'admin_')
      if (uid.startsWith('admin_')) {
        developer.log(
          'Database-based admin detected: $uid',
          name: 'SheikhService',
        );
        return true; // Database-based admins are always admin
      }

      // For Firebase Auth-based users, check Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      final isAdminUser = userDoc.exists && userDoc.data()?['is_admin'] == true;

      developer.log(
        'Firebase Auth admin check for $uid: $isAdminUser',
        name: 'SheikhService',
      );

      return isAdminUser;
    } on TimeoutException {
      developer.log(
        'Timeout checking admin status',
        name: 'SheikhService',
        error: 'Timeout',
      );
      return false;
    } catch (e) {
      developer.log(
        'Error checking admin status',
        name: 'SheikhService',
        error: e,
      );
      return false;
    }
  }

  /// Create a new Sheikh account (admin only)
  /// Allocates ID transactionally during this call
  Future<Map<String, dynamic>> createSheikh({
    required String name,
    required String email,
    required String password,
    required String category,
    required String currentAdminUid,
  }) async {
    try {
      // Verify current user is admin
      final isAdminUser = await isAdmin(currentAdminUid);
      if (!isAdminUser) {
        throw SheikhServiceException('ليس لديك صلاحية لإنشاء حسابات الشيوخ');
      }

      // Validate inputs
      if (name.trim().isEmpty) {
        throw SheikhServiceException('يرجى إدخال اسم الشيخ');
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        throw SheikhServiceException('يرجى إدخال بريد إلكتروني صحيح');
      }
      // DEMO ONLY — Allow weak passwords for demo purposes (not for production)
      if (password.length < 6) {
        throw SheikhServiceException(
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        );
      }

      // Allocate Sheikh ID atomically
      final sheikhId = await allocateNextSheikhId();

      developer.log(
        'Creating Sheikh with ID: $sheikhId',
        name: 'SheikhService',
      );

      // Create Firebase Auth user
      UserCredential userCredential;
      try {
        userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(_timeout);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw SheikhServiceException('البريد الإلكتروني مستخدم بالفعل');
        } else if (e.code == 'weak-password') {
          throw SheikhServiceException('كلمة المرور ضعيفة جداً');
        } else {
          throw SheikhServiceException('فشل إنشاء الحساب: ${e.message}');
        }
      } on TimeoutException {
        throw SheikhServiceException(
          'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
        );
      }

      if (userCredential.user == null) {
        throw Exception('فشل في إنشاء الحساب');
      }
      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception('فشل في إنشاء الحساب');
      }

      // Create Firestore document
      await _firestore
          .collection('users')
          .doc(uid)
          .set({
            'uid': uid,
            'name': name.trim(),
            'email': email.trim(),
            'role': 'sheikh',
            'uniqueId': sheikhId, // Store as uniqueId for login queries
            'sheikhId': sheikhId, // Keep for backward compatibility
            'secret': password, // Store the password as secret for login
            'status': 'active', // Set status to active
            'category': category.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentAdminUid,
            'enabled': true,
          })
          .timeout(_timeout);

      developer.log(
        'Sheikh created successfully: $sheikhId',
        name: 'SheikhService',
      );

      return {
        'success': true,
        'sheikhId': sheikhId,
        'uid': uid,
        'message': 'تم إنشاء حساب الشيخ برقم: $sheikhId',
      };
    } on SheikhServiceException {
      rethrow;
    } on TimeoutException {
      developer.log('Timeout creating Sheikh', name: 'SheikhService');
      throw SheikhServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error creating Sheikh', name: 'SheikhService', error: e);
      throw SheikhServiceException('حدث خطأ أثناء إنشاء حساب الشيخ: $e');
    }
  }

  /// Count total sheikhs (admin only) - simple reliable query
  Future<int> countSheikhs() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'sheikh')
          .get()
          .timeout(_timeout);

      return querySnapshot.docs.length;
    } on TimeoutException {
      developer.log('Timeout counting sheikhs', name: 'SheikhService');
      return 0;
    } catch (e) {
      developer.log('Error counting sheikhs', name: 'SheikhService', error: e);
      return 0;
    }
  }

  /// List sheikhs with graceful fallback for missing composite index
  /// Tries full query (with orderBy); falls back to simple query if index missing
  Future<SheikhQueryResult> listSheikhs({
    String? search,
    int pageSize = 50,
  }) async {
    try {
      // Try FULL query first: role == 'sheikh' + orderBy createdAt desc
      developer.log(
        'Attempting full query with orderBy createdAt',
        name: 'SheikhService',
      );

      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'sheikh')
          .orderBy('createdAt', descending: true)
          .limit(pageSize)
          .get()
          .timeout(_timeout);

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply client-side search if provided
      List<Map<String, dynamic>> filteredItems = items;
      if (search != null && search.trim().isNotEmpty) {
        final searchLower = search.toLowerCase();
        filteredItems = items.where((item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final email = (item['email'] ?? '').toString().toLowerCase();
          final sheikhId = (item['sheikhId'] ?? '').toString();
          return name.contains(searchLower) ||
              email.contains(searchLower) ||
              sheikhId.contains(searchLower);
        }).toList();
      }

      developer.log(
        'Full query succeeded: ${items.length} sheikhs loaded',
        name: 'SheikhService',
      );

      return SheikhQueryResult(items: filteredItems, fallbackMode: false);
    } on FirebaseException catch (e) {
      // Check if this is a missing index error
      if (e.code == 'failed-precondition') {
        developer.log(
          'Composite index missing, switching to fallback mode',
          name: 'SheikhService',
          error: e.message,
        );

        // Extract index creation URL from error message
        String? indexUrl;
        if (e.message != null) {
          final urlMatch = RegExp(
            r'https://console\.firebase\.google\.com[^\s]+',
          ).firstMatch(e.message ?? '');
          if (urlMatch != null) {
            indexUrl = urlMatch.group(0);
            developer.log(
              'Index creation URL: $indexUrl',
              name: 'SheikhService',
            );
          }
        }

        // FALLBACK: Simple query without orderBy
        try {
          developer.log(
            'Executing fallback query (no orderBy)',
            name: 'SheikhService',
          );

          final fallbackSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'sheikh')
              .limit(pageSize)
              .get()
              .timeout(_timeout);

          final items = fallbackSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Client-side sorting by createdAt if available
          items.sort((a, b) {
            final aDate = a['createdAt'];
            final bDate = b['createdAt'];
            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate); // Descending
            }
            return 0;
          });

          // Apply client-side search if provided
          List<Map<String, dynamic>> filteredItems = items;
          if (search != null && search.trim().isNotEmpty) {
            final searchLower = search.toLowerCase();
            filteredItems = items.where((item) {
              final name = (item['name'] ?? '').toString().toLowerCase();
              final email = (item['email'] ?? '').toString().toLowerCase();
              final sheikhId = (item['sheikhId'] ?? '').toString();
              return name.contains(searchLower) ||
                  email.contains(searchLower) ||
                  sheikhId.contains(searchLower);
            }).toList();
          }

          developer.log(
            'Fallback query succeeded: ${items.length} sheikhs loaded',
            name: 'SheikhService',
          );

          return SheikhQueryResult(
            items: filteredItems,
            fallbackMode: true,
            indexCreateUrl: indexUrl,
          );
        } catch (fallbackError) {
          developer.log(
            'Fallback query also failed',
            name: 'SheikhService',
            error: fallbackError,
          );
          throw SheikhServiceException(
            'فشل في تحميل قائمة الشيوخ حتى بالوضع المبسط: $fallbackError',
          );
        }
      } else if (e.code == 'permission-denied') {
        throw SheikhServiceException('لا تملك صلاحية عرض هذه القائمة');
      } else if (e.code == 'unavailable') {
        throw SheikhServiceException('تعذّر الاتصال. حاول مجددًا.');
      }

      // Other Firestore errors
      developer.log(
        'Firestore error listing sheikhs',
        name: 'SheikhService',
        error: e,
      );
      throw SheikhServiceException('فشل في تحميل قائمة الشيوخ: ${e.message}');
    } on TimeoutException {
      developer.log('Timeout listing sheikhs', name: 'SheikhService');
      throw SheikhServiceException(
        'انتهت المهلة. تحقق من الاتصال وحاول مجددًا.',
      );
    } catch (e) {
      developer.log('Error listing sheikhs', name: 'SheikhService', error: e);
      throw SheikhServiceException('فشل في تحميل قائمة الشيوخ: $e');
    }
  }

  /// Get Sheikh details by ID
  Future<Map<String, dynamic>?> getSheikhById(String sheikhId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('sheikhId', isEqualTo: sheikhId)
          .where('role', isEqualTo: 'sheikh')
          .limit(1)
          .get()
          .timeout(_timeout);

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final data = querySnapshot.docs.first.data();
      data['id'] = querySnapshot.docs.first.id;
      return data;
    } on TimeoutException {
      developer.log('Timeout getting Sheikh by ID', name: 'SheikhService');
      return null;
    } catch (e) {
      developer.log(
        'Error getting Sheikh by ID',
        name: 'SheikhService',
        error: e,
      );
      return null;
    }
  }
}
