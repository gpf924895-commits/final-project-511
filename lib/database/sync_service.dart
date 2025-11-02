import 'dart:developer' as developer;

/// SyncService - Disabled for offline-only mode
/// This service was used for Firestore to SQLite sync
/// In offline-only mode, all data is stored directly in SQLite
class SyncService {
  /// Sync users - disabled in offline mode
  Future<void> syncUsers({bool fullSync = false}) async {
    developer.log('syncUsers: Disabled in offline-only mode');
  }

  /// Sync subcategories - disabled in offline mode
  Future<void> syncSubcategories({bool fullSync = false}) async {
    developer.log('syncSubcategories: Disabled in offline-only mode');
  }

  /// Sync lectures - disabled in offline mode
  Future<void> syncLectures({bool fullSync = false}) async {
    developer.log('syncLectures: Disabled in offline-only mode');
  }

  /// Sync all collections - disabled in offline mode
  Future<void> syncAll({bool forceFullSync = false}) async {
    developer.log('syncAll: Disabled in offline-only mode');
  }

  /// Live sync lectures - disabled in offline mode
  Stream<void> liveSyncLectures() async* {
    developer.log('liveSyncLectures: Disabled in offline-only mode');
    // Return empty stream
    yield* Stream.empty();
  }

  /// Get sync status - returns empty status in offline mode
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'last_users_sync': null,
      'last_subcategories_sync': null,
      'last_lectures_sync': null,
      'last_error': 'Offline-only mode: Sync disabled',
    };
  }
}
