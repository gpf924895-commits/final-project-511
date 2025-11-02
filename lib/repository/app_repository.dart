import 'package:new_project/repository/local_repository.dart';
import 'dart:developer' as developer;

/// AppRepository - Local SQLite-only implementation
/// All operations use LocalRepository directly
class AppRepository {
  final LocalRepository _repository = LocalRepository();

  /// Initialize repository - opens DB
  Future<void> init() async {
    try {
      developer.log('Initializing AppRepository (offline-only)...');
      await _repository.getTableCounts(); // Ensure DB is open
      developer.log('Database opened');
    } catch (e) {
      developer.log('Error initializing repository: $e', name: 'AppRepository');
      rethrow;
    }
  }

  // Delegate all methods to LocalRepository
  // Users
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) => _repository.registerUser(
    username: username,
    email: email,
    password: password,
  );

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) => _repository.loginUser(email: email, password: password);

  Future<Map<String, dynamic>> loginAdmin({
    required String username,
    required String password,
  }) => _repository.loginAdmin(username: username, password: password);

  Future<List<Map<String, dynamic>>> getAllUsers() => _repository.getAllUsers();

  Future<Map<String, dynamic>?> getUserProfile(String userId) =>
      _repository.getUserProfile(userId);

  // Subcategories
  Future<List<Map<String, dynamic>>> getSubcategoriesBySection(
    String section,
  ) => _repository.getSubcategoriesBySection(section);

  Future<Map<String, dynamic>> addSubcategory({
    required String name,
    required String section,
    String? description,
    String? iconName,
  }) => _repository.addSubcategory(
    name: name,
    section: section,
    description: description,
    iconName: iconName,
  );

  // Lectures
  Future<List<Map<String, dynamic>>> getLecturesBySection(String section) =>
      _repository.getLecturesBySection(section);

  Future<List<Map<String, dynamic>>> getLecturesBySubcategory(
    String subcategoryId,
  ) => _repository.getLecturesBySubcategory(subcategoryId);

  Future<Map<String, dynamic>> addLecture({
    required String title,
    required String description,
    String? videoPath,
    required String section,
    String? subcategoryId,
  }) => _repository.addLecture(
    title: title,
    description: description,
    videoPath: videoPath,
    section: section,
    subcategoryId: subcategoryId,
  );

  // Search
  Future<List<Map<String, dynamic>>> searchLectures(String query) =>
      _repository.searchLectures(query);
}
