import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Authenticate Sheikh using ONLY sheikhId and password
  /// No email dependency - direct Firestore validation
  Future<Map<String, dynamic>> authenticateSheikh(
    String sheikhId,
    String password,
  ) async {
    try {
      print('[SheikhAuthService] Authenticating sheikh with ID: $sheikhId');

      // Input validation
      if (sheikhId.trim().isEmpty || password.trim().isEmpty) {
        return {
          'success': false,
          'message': 'الرجاء إدخال رقم الشيخ وكلمة المرور',
        };
      }

      // Enforce exactly 8 digits policy
      final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (normalized.isEmpty) {
        return {'success': false, 'message': 'رقم الشيخ غير صحيح'};
      }
      
      // Enforce exactly 8 digits - no padding, must be exactly 8 digits
      if (normalized.length != 8) {
        return {'success': false, 'message': 'رقم الشيخ يجب أن يكون 8 أرقام بالضبط'};
      }
      
      final sheikhId8Digit = normalized; // Use as-is since it's exactly 8 digits

      print('[SheikhAuthService] Using 8-digit sheikhId: $sheikhId8Digit');

      // Find Sheikh document by sheikhId (primary field)
      DocumentSnapshot? sheikhDoc;
      Map<String, dynamic>? sheikhData;

      try {
        // Primary query: search by sheikhId field
        final querySnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'sheikh')
            .where('sheikhId', isEqualTo: sheikhId8Digit)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        if (querySnapshot.docs.isNotEmpty) {
          sheikhDoc = querySnapshot.docs.first;
          sheikhData = sheikhDoc.data() as Map<String, dynamic>?;
          print('[SheikhAuthService] FOUND_DOC: Sheikh document found by sheikhId field');
        }
      } on FirebaseException catch (e) {
        print('[SheikhAuthService] Primary query failed: ${e.code} - ${e.message}');
        
        if (e.code == 'failed-precondition') {
          // Fallback: get all sheikhs and filter manually
          print('[SheikhAuthService] Using fallback query method');
          final allSheikhs = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'sheikh')
              .get()
              .timeout(const Duration(seconds: 10));

          final matchingDocs = allSheikhs.docs.where((doc) {
            final data = doc.data();
            final docSheikhId = data['sheikhId'] as String?;
            final docUniqueId = data['uniqueId'] as String?;
            return docSheikhId == sheikhId8Digit || docUniqueId == sheikhId8Digit;
          }).toList();

          if (matchingDocs.isNotEmpty) {
            sheikhDoc = matchingDocs.first;
            sheikhData = sheikhDoc.data() as Map<String, dynamic>?;
            print('[SheikhAuthService] FOUND_DOC: Sheikh document found via fallback query');
          }
        }
      }

      // If not found by sheikhId, try uniqueId field (legacy support)
      if (sheikhDoc == null) {
        print('[SheikhAuthService] Trying uniqueId field...');
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'sheikh')
              .where('uniqueId', isEqualTo: sheikhId8Digit)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));

          if (querySnapshot.docs.isNotEmpty) {
            sheikhDoc = querySnapshot.docs.first;
            sheikhData = sheikhDoc.data() as Map<String, dynamic>?;
            print('[SheikhAuthService] FOUND_DOC: Sheikh document found by uniqueId field');
          }
        } catch (e) {
          print('[SheikhAuthService] uniqueId query failed: $e');
        }
      }

      // Check if Sheikh was found
      if (sheikhDoc == null || sheikhData == null) {
        print('[SheikhAuthService] No Sheikh document found for sheikhId: $sheikhId8Digit');
        return {'success': false, 'message': 'رقم الشيخ أو كلمة المرور غير صحيحة'};
      }

      print('[SheikhAuthService] CHECK_PASSWORD: Verifying password for sheikhId: $sheikhId8Digit');
      
      // Verify password first (check both secret and password fields)
      final storedPassword = sheikhData['secret'] as String?;
      final storedPasswordAlt = sheikhData['password'] as String?;
      
      if (storedPassword != password && storedPasswordAlt != password) {
        print('[SheikhAuthService] CHECK_PASSWORD: Password verification failed');
        return {'success': false, 'message': 'رقم الشيخ أو كلمة المرور غير صحيحة'};
      }
      
      print('[SheikhAuthService] CHECK_PASSWORD: Password verification successful');

      print('[SheikhAuthService] CHECK_ROLE_ACTIVE: Verifying role and active status');
      
      // Verify role is sheikh
      if (sheikhData['role'] != 'sheikh') {
        print('[SheikhAuthService] CHECK_ROLE_ACTIVE: Role verification failed - role is ${sheikhData['role']}');
        return {'success': false, 'message': 'هذا الحساب ليس حساب شيخ'};
      }

      // Check if account is active
      final status = (sheikhData['status'] as String?)?.toLowerCase();
      final isActive = sheikhData['isActive'] as bool?;
      final enabled = sheikhData['enabled'] as bool?;
      
      if (status != 'active' && isActive != true && enabled != true) {
        print('[SheikhAuthService] CHECK_ROLE_ACTIVE: Account is not active - status: $status, isActive: $isActive, enabled: $enabled');
        return {'success': false, 'message': 'الحساب غير مفعّل'};
      }
      
      print('[SheikhAuthService] CHECK_ROLE_ACTIVE: Role and active status verification successful');

      // Success - return Sheikh data
      print('[SheikhAuthService] Authentication successful for sheikhId: $sheikhId8Digit');
      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'sheikh': {
          'uid': sheikhDoc.id,
          'name': sheikhData['name'],
          'email': sheikhData['email'],
          'uniqueId': sheikhId8Digit, // Use the exact 8-digit sheikhId
          'role': 'sheikh',
          'category': sheikhData['category'],
          'isActive': status == 'active' || isActive == true || enabled == true,
        },
      };
    } catch (e) {
      print('[SheikhAuthService] Error during authentication: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول'};
    }
  }

  /// Validate input format
  String? getErrorMessage(String sheikhId, String password) {
    if (sheikhId.trim().isEmpty || password.trim().isEmpty) {
      return 'الرجاء إدخال رقم الشيخ وكلمة المرور';
    }

    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      return 'رقم الشيخ غير صحيح';
    }

    return null;
  }

  /// Legacy method for backward compatibility
  Future<bool> validateSheikh(String sheikhId, String password) async {
    final result = await authenticateSheikh(sheikhId, password);
    return result['success'] == true;
  }

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>> validateSheikhDetailed(
    String sheikhId,
    String password,
  ) async {
    return await authenticateSheikh(sheikhId, password);
  }


  /// Normalize sheikhId to 8-digit string (enforces exactly 8 digits)
  String normalizeSheikhId(String sheikhId) {
    final normalized = sheikhId.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return '';
    
    // Enforce exactly 8 digits - no padding, must be exactly 8 digits
    if (normalized.length != 8) {
      return ''; // Return empty string for invalid length
    }
    
    return normalized; // Return as-is since it's exactly 8 digits
  }
}