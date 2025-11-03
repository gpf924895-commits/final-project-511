# Database Migration Guide - AppDatabase Integration

## Overview

This document explains how to complete the migration from `LocalSQLiteService` to `AppDatabase` for all remaining methods in `LocalRepository`.

## Current Status

- ✅ `AppDatabase` singleton created with versioned migrations
- ✅ Defensive retry mechanism implemented
- ✅ `sheikhs` table included in v1 migration (fixes fresh install crash)
- ✅ Main initialization updated
- ⚠️ Some methods in `LocalRepository` still need updates (28 remaining instances)

## Remaining Work

There are 28 instances of `await _dbService.db` in `LocalRepository` that need to be wrapped with `_withRetry`.

### Pattern to Follow

**Before:**
```dart
Future<SomeType> someMethod() async {
  try {
    final db = await _dbService.db;
    // ... database operations ...
    return result;
  } catch (e) {
    // ... error handling ...
  }
}
```

**After:**
```dart
Future<SomeType> someMethod() async {
  try {
    return await _withRetry((db) async {
      // ... database operations ...
      return result;
    }, 'someMethod');
  } catch (e) {
    // ... error handling ...
  }
}
```

### Methods Needing Updates

The following methods in `lib/repository/local_repository.dart` still need updates:
- Line 316: `updateUserProfile`
- Line 349: `getSubcategoriesBySection`
- Line 402: `addSubcategory`
- Line 422: `updateSubcategory`
- Line 444: `deleteSubcategory`
- Line 479: `addLecture`
- Line 505: `getAllLectures`
- Line 529: `getLecturesBySection`
- Line 560: `getLectureById`
- Line 584: `updateLecture`
- Line 611: `deleteLecture`
- Line 636: `addSheikhLecture`
- Line 665: `getSheikhLectures`
- Line 688: `updateSheikhLecture`
- Line 705: `deleteSheikhLecture`
- Line 786: `archiveLecture`
- Line 833: `archiveLecturesBySheikh`
- Line 861: `getTableCounts`
- Line 895: `updateUserProfile` (if duplicate)
- Line 932: (various methods)
- Line 956: (various methods)
- Line 979: (various methods)
- Line 1018: (various methods)
- Line 1077: (various methods)
- Line 1119: `initializeDefaultSubcategoriesIfEmpty`
- Line 1146: `ensureDefaultAdmin`
- Line 1170: (archive methods)
- Line 1257: `updateUserRoleAndUniqueId`

## Automated Update Script

You can use a find-and-replace pattern to update most instances:

1. Find: `final db = await _dbService.db;`
2. Replace with: (manually wrap with `_withRetry`)

Or use a more sophisticated script that:
1. Finds methods starting with `Future` that contain `await _dbService.db`
2. Wraps the entire method body (from `{` to the matching `}`) with `_withRetry`

## Testing

After completing updates, test:
1. Fresh install (delete DB file, restart app)
2. Upgrade from old version
3. Concurrent access during initialization
4. "no such table" error recovery

## Migration Notes

- All migrations run in transactions for safety
- Defensive retry automatically handles missing table errors
- Health check verifies critical tables exist
- Backups created before corruption recovery

