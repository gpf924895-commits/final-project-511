import 'package:cloud_firestore/cloud_firestore.dart';

class HierarchyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Categories Collection
  static const String categoriesCollection = 'categories';
  static const String subcategoriesCollection = 'subcategories';
  static const String lecturesCollection = 'lectures';

  // ==================== Categories Management ====================

  /// Add a new category
  Future<Map<String, dynamic>> addCategory({
    required String section,
    required String name,
    String? description,
    int? order,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection(categoriesCollection).add({
        'section': section,
        'name': name,
        'description': description,
        'order': order ?? 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      return {
        'success': true,
        'message': 'تم إضافة الفئة بنجاح',
        'categoryId': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء إضافة الفئة: $e'};
    }
  }

  /// Update category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (description != null) updateData['description'] = description;
      if (order != null) updateData['order'] = order;
      if (isActive != null) updateData['isActive'] = isActive;

      await _firestore
          .collection(categoriesCollection)
          .doc(categoryId)
          .update(updateData);

      return {'success': true, 'message': 'تم تحديث الفئة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تحديث الفئة: $e'};
    }
  }

  /// Delete category (soft delete by setting isActive = false)
  Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(categoriesCollection).doc(categoryId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم حذف الفئة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء حذف الفئة: $e'};
    }
  }

  /// Get categories for a section
  Future<List<Map<String, dynamic>>> getCategoriesBySection(
    String section,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(categoriesCollection)
          .where('section', isEqualTo: section)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading categories for section $section: $e');
      return [];
    }
  }

  /// Get real-time stream of categories for a section
  Stream<List<Map<String, dynamic>>> getCategoriesStream(String section) {
    return _firestore
        .collection(categoriesCollection)
        .where('section', isEqualTo: section)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // ==================== Subcategories Management ====================

  /// Add a new subcategory
  Future<Map<String, dynamic>> addSubcategory({
    required String section,
    required String categoryId,
    required String categoryName,
    required String name,
    String? description,
    int? order,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection(subcategoriesCollection).add({
        'section': section,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'name': name,
        'description': description,
        'order': order ?? 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      return {
        'success': true,
        'message': 'تم إضافة الفئة الفرعية بنجاح',
        'subcategoryId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إضافة الفئة الفرعية: $e',
      };
    }
  }

  /// Update subcategory
  Future<Map<String, dynamic>> updateSubcategory({
    required String subcategoryId,
    required String name,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (description != null) updateData['description'] = description;
      if (order != null) updateData['order'] = order;
      if (isActive != null) updateData['isActive'] = isActive;

      await _firestore
          .collection(subcategoriesCollection)
          .doc(subcategoryId)
          .update(updateData);

      return {'success': true, 'message': 'تم تحديث الفئة الفرعية بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الفئة الفرعية: $e',
      };
    }
  }

  /// Delete subcategory (soft delete by setting isActive = false)
  Future<Map<String, dynamic>> deleteSubcategory(String subcategoryId) async {
    try {
      await _firestore
          .collection(subcategoriesCollection)
          .doc(subcategoryId)
          .update({
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
          });

      return {'success': true, 'message': 'تم حذف الفئة الفرعية بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء حذف الفئة الفرعية: $e',
      };
    }
  }

  /// Get subcategories for a category
  Future<List<Map<String, dynamic>>> getSubcategoriesByCategory(
    String categoryId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(subcategoriesCollection)
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading subcategories for category $categoryId: $e');
      return [];
    }
  }

  /// Get real-time stream of subcategories for a category
  Stream<List<Map<String, dynamic>>> getSubcategoriesStream(String categoryId) {
    return _firestore
        .collection(subcategoriesCollection)
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // ==================== Lectures with Hierarchy ====================

  /// Get lectures with hierarchy filtering
  Future<List<Map<String, dynamic>>> getLecturesWithHierarchy({
    required String section,
    String? categoryId,
    String? subcategoryId,
  }) async {
    try {
      Query query = _firestore
          .collection(lecturesCollection)
          .where('section', isEqualTo: section)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (subcategoryId != null) {
        query = query.where('subcategoryId', isEqualTo: subcategoryId);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading lectures with hierarchy: $e');
      return [];
    }
  }

  /// Get real-time stream of lectures with hierarchy filtering
  Stream<List<Map<String, dynamic>>> getLecturesStream({
    required String section,
    String? categoryId,
    String? subcategoryId,
  }) {
    Query query = _firestore
        .collection(lecturesCollection)
        .where('section', isEqualTo: section)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (subcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: subcategoryId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==================== Helper Methods ====================

  /// Get section name in Arabic
  String getSectionNameAr(String section) {
    switch (section) {
      case 'fiqh':
        return 'الفقه';
      case 'hadith':
        return 'الحديث';
      case 'seerah':
        return 'السيرة';
      case 'tafsir':
        return 'التفسير';
      default:
        return section;
    }
  }

  /// Get section key from Arabic name
  String getSectionKey(String sectionNameAr) {
    switch (sectionNameAr) {
      case 'الفقه':
        return 'fiqh';
      case 'الحديث':
        return 'hadith';
      case 'السيرة':
        return 'seerah';
      case 'التفسير':
        return 'tafsir';
      default:
        return sectionNameAr.toLowerCase();
    }
  }
}
