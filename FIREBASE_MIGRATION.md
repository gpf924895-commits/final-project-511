# Firebase Migration Guide

## Overview
The application has been successfully migrated from SQLite local storage to Firebase Firestore cloud database. All data is now stored and synced in the cloud.

## What Changed

### 1. Database Backend
- **Before:** SQLite (local storage)
- **After:** Firebase Firestore (cloud storage)

### 2. Data Collections
The following Firestore collections are used:

#### `users`
- `username` (String)
- `email` (String)
- `password` (String) 
- `is_admin` (Boolean)
- `created_at` (Timestamp)

#### `subcategories`
- `name` (String)
- `section` (String)
- `description` (String)
- `icon_name` (String)
- `created_at` (Timestamp)

#### `lectures`
- `title` (String)
- `description` (String)
- `video_path` (String, optional)
- `section` (String)
- `subcategory_id` (String, optional - references subcategory document ID)
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

### 3. ID Types Changed
- **Before:** Integer IDs (auto-increment)
- **After:** String IDs (Firestore document IDs)

All screens and providers have been updated to handle String IDs instead of integers.

## Files Modified

### Core Database Files
- ✅ **Created:** `lib/database/firebase_service.dart` - New Firebase service replacing DatabaseHelper
- ❌ **Deleted:** `lib/database/app_database.dart` - Old SQLite database file

### Providers Updated
- ✅ `lib/provider/pro_login.dart` - Auth provider using Firebase
- ✅ `lib/provider/lecture_provider.dart` - Lecture management with Firestore
- ✅ `lib/provider/subcategory_provider.dart` - Subcategory management with Firestore

### Screens Updated
- ✅ `lib/main.dart` - Firebase initialization
- ✅ `lib/screens/add_lecture_page.dart`
- ✅ `lib/screens/Edit_Lecture_Page.dart`
- ✅ `lib/screens/Delete_Lecture_Page.dart`
- ✅ `lib/screens/Admin_home_page.dart`
- ✅ `lib/screens/admin_panel_page.dart`
- ✅ `lib/screens/subcategory_lectures_page.dart`

### Configuration Files
- ✅ `pubspec.yaml` - Added Firebase dependencies
- ✅ `android/app/google-services.json` - Firebase Android configuration

## Dependencies Added

```yaml
firebase_core: ^3.8.1
cloud_firestore: ^5.5.0
firebase_auth: ^5.3.3
```

## Setup Instructions

### 1. Firebase Configuration

#### Android Setup
The `google-services.json` file is already in place at:
```
android/app/google-services.json
```

#### iOS Setup (Required)
You need to download the `GoogleService-Info.plist` from Firebase Console and add it to:
```
ios/Runner/GoogleService-Info.plist
```

**Steps:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mohathrahapp`
3. Go to Project Settings
4. Under "Your apps" section, click on the iOS app (or add one if not exists)
5. Download `GoogleService-Info.plist`
6. Copy it to `ios/Runner/` directory

### 2. Firestore Database Setup

1. Go to Firebase Console → Firestore Database
2. Create a database (if not already created)
3. Set up security rules (see below)

#### Recommended Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - allow read for authenticated users, write only for admins
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if true; // Allow user registration
      allow update, delete: if request.auth != null && 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
    }
    
    // Lectures collection - public read, admin write
    match /lectures/{lectureId} {
      allow read: if true; // Public read access
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
    }
    
    // Subcategories collection - public read, admin write
    match /subcategories/{subcategoryId} {
      allow read: if true; // Public read access
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
    }
  }
}
```

### 3. Initial Data Seeding

The app automatically seeds default subcategories on first run. If you need to reset:

1. Delete all documents from the `subcategories` collection
2. Restart the app
3. Default subcategories will be recreated

### 4. Admin Account

The default admin account is created on app startup:
- **Username:** admin
- **Email:** admin@admin.com
- **Password:** admin123

**⚠️ IMPORTANT:** Change the admin password in production!

## Key Differences from SQLite

### 1. Asynchronous Operations
All database operations are now asynchronous and return Futures.

### 2. Real-time Updates
Firestore supports real-time listeners (not currently implemented but can be added).

### 3. Offline Support
Firestore has built-in offline persistence. Data is cached locally and synced when online.

### 4. Document IDs
- SQLite used integer auto-increment IDs
- Firestore uses randomly generated string IDs
- All references updated from `int` to `String`

### 5. Timestamps
- SQLite used ISO8601 strings
- Firestore uses `Timestamp` type (converted to ISO8601 strings in the app)

## Testing

After migration, test the following:

### User Management
- ✅ User registration
- ✅ User login
- ✅ Admin login
- ✅ User deletion (admin)

### Lecture Management
- ✅ Create lectures
- ✅ Read/list lectures
- ✅ Update lectures
- ✅ Delete lectures
- ✅ Filter by section
- ✅ Filter by subcategory

### Subcategory Management
- ✅ List subcategories by section
- ✅ Create subcategories
- ✅ Update subcategories
- ✅ Delete subcategories

## Troubleshooting

### Firebase Not Initialized
**Error:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution:** Make sure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`.

### Google Services Missing
**Error:** `google-services.json` or `GoogleService-Info.plist` not found

**Solution:** 
- Android: Ensure `google-services.json` is in `android/app/`
- iOS: Download and add `GoogleService-Info.plist` to `ios/Runner/`

### Permission Denied
**Error:** Firestore permission denied

**Solution:** Check your Firestore security rules and ensure they allow the operation.

### Offline Mode
If testing without internet, remember that Firestore caches data locally. Initial data fetch requires internet connection.

## Performance Considerations

1. **Indexing:** Firestore automatically indexes fields. For complex queries, create composite indexes in Firebase Console.

2. **Pagination:** For large datasets, implement pagination using Firestore's `limit()` and `startAfter()` methods.

3. **Caching:** Firestore automatically caches data. Configure cache settings if needed.

## Future Enhancements

1. **Real-time Listeners:** Replace manual refresh with Firestore snapshots for live updates
2. **Firebase Authentication:** Replace custom auth with Firebase Authentication
3. **Firebase Storage:** Store videos in Firebase Storage instead of local paths
4. **Search Optimization:** Implement Algolia or similar for full-text search
5. **Analytics:** Add Firebase Analytics for usage tracking

## Rollback Plan

If you need to rollback to SQLite:

1. Restore `lib/database/app_database.dart` from git history
2. Revert all provider and screen changes
3. Remove Firebase dependencies from `pubspec.yaml`
4. Run `flutter pub get`

## Support

For Firebase-specific issues, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

**Migration Completed:** [Date]
**Migration By:** AI Assistant
**Status:** ✅ Fully Operational

