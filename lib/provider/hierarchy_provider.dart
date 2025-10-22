import 'package:flutter/material.dart';
import 'package:new_project/services/hierarchy_service.dart';

class HierarchyProvider extends ChangeNotifier {
  final HierarchyService _hierarchyService = HierarchyService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedSection;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _lectures = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedSection => _selectedSection;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get subcategories => _subcategories;
  List<Map<String, dynamic>> get lectures => _lectures;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // ==================== Categories Management ====================

  /// Set selected section and load categories
  Future<void> setSelectedSection(String section) async {
    _selectedSection = section;
    _subcategories.clear(); // Clear dependent data
    _lectures.clear();
    notifyListeners();
    await loadCategoriesBySection(section);
  }

  /// Load categories for a section
  Future<void> loadCategoriesBySection(String section) async {
    _setLoading(true);
    _setError(null);

    try {
      _categories = await _hierarchyService.getCategoriesBySection(section);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل الفئات: $e');
    }
  }

  /// Add a new category
  Future<bool> addCategory({
    required String section,
    required String name,
    String? description,
    int? order,
    required String createdBy,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.addCategory(
        section: section,
        name: name,
        description: description,
        order: order,
        createdBy: createdBy,
      );

      if (result['success']) {
        // Reload categories
        await loadCategoriesBySection(section);
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في إضافة الفئة: $e');
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        order: order,
        isActive: isActive,
      );

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحديث الفئة: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.deleteCategory(categoryId);

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في حذف الفئة: $e');
      return false;
    }
  }

  // ==================== Subcategories Management ====================

  /// Load subcategories for a category
  Future<void> loadSubcategoriesByCategory(String categoryId) async {
    _setLoading(true);
    _setError(null);

    try {
      _subcategories = await _hierarchyService.getSubcategoriesByCategory(
        categoryId,
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل الفئات الفرعية: $e');
    }
  }

  /// Add a new subcategory
  Future<bool> addSubcategory({
    required String section,
    required String categoryId,
    required String categoryName,
    required String name,
    String? description,
    int? order,
    required String createdBy,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.addSubcategory(
        section: section,
        categoryId: categoryId,
        categoryName: categoryName,
        name: name,
        description: description,
        order: order,
        createdBy: createdBy,
      );

      if (result['success']) {
        // Reload subcategories
        await loadSubcategoriesByCategory(categoryId);
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في إضافة الفئة الفرعية: $e');
      return false;
    }
  }

  /// Update subcategory
  Future<bool> updateSubcategory({
    required String subcategoryId,
    required String name,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.updateSubcategory(
        subcategoryId: subcategoryId,
        name: name,
        description: description,
        order: order,
        isActive: isActive,
      );

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحديث الفئة الفرعية: $e');
      return false;
    }
  }

  /// Delete subcategory
  Future<bool> deleteSubcategory(String subcategoryId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _hierarchyService.deleteSubcategory(subcategoryId);

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في حذف الفئة الفرعية: $e');
      return false;
    }
  }

  // ==================== Lectures Management ====================

  /// Load lectures with hierarchy filtering
  Future<void> loadLecturesWithHierarchy({
    required String section,
    String? categoryId,
    String? subcategoryId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _lectures = await _hierarchyService.getLecturesWithHierarchy(
        section: section,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('حدث خطأ في تحميل المحاضرات: $e');
    }
  }

  // ==================== Stream Methods ====================

  /// Get categories stream for a section
  Stream<List<Map<String, dynamic>>> getCategoriesStream(String section) {
    return _hierarchyService.getCategoriesStream(section);
  }

  /// Get subcategories stream for a category
  Stream<List<Map<String, dynamic>>> getSubcategoriesStream(String categoryId) {
    return _hierarchyService.getSubcategoriesStream(categoryId);
  }

  /// Get lectures stream with hierarchy filtering
  Stream<List<Map<String, dynamic>>> getLecturesStream({
    required String section,
    String? categoryId,
    String? subcategoryId,
  }) {
    return _hierarchyService.getLecturesStream(
      section: section,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    );
  }

  // ==================== Helper Methods ====================

  /// Get section name in Arabic
  String getSectionNameAr(String section) {
    return _hierarchyService.getSectionNameAr(section);
  }

  /// Get section key from Arabic name
  String getSectionKey(String sectionNameAr) {
    return _hierarchyService.getSectionKey(sectionNameAr);
  }

  /// Clear all data
  void clearData() {
    _categories.clear();
    _subcategories.clear();
    _lectures.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
