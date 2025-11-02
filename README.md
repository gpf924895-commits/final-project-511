# new_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firestore Indexes Required

This application uses composite queries that require Firestore indexes to be created. When you first run queries that need indexes, Firestore will provide a console link to create them automatically.

### Required Indexes

#### 1. Sheikh List (Admin Panel)

**Collection Path:** `users`

**Fields to Index:**
1. `role` (Ascending) - Equality filter
2. `createdAt` (Descending) - Sort order

**Query:** Used to list all sheikhs in the admin panel, sorted by creation date (newest first).

**How to Create:**

1. **Automatic (Recommended):**
   - Log in as admin and navigate to "عرض الشيوخ" (Sheikh List)
   - If the index is missing, the app will show an orange banner
   - Click "نسخ رابط إنشاء الفهرس" to copy the index creation link
   - Open the link in your browser
   - Click "Create Index" button in Firebase Console
   - Wait for index to build (usually 1-5 minutes)

2. **Manual via Firebase Console:**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Navigate to **Firestore Database** → **Indexes** tab
   - Click **Create Index**
   - Select **Collection** mode
   - Enter collection ID: `users`
   - Add fields:
     - Field: `role`, Order: `Ascending`
     - Field: `createdAt`, Order: `Descending`
   - Query scope: `Collection`
   - Click **Create Index**
   - Wait for status to change from "Building" to "Enabled"

**Fallback Behavior:** If this index is not created, the app will automatically fall back to a simpler query without ordering. The list will still work, but sorting and search may be less efficient. The app will display a warning banner prompting you to create the index.

#### 2. Sheikhs Collection (per Subcategory)

**Collection Path (Collection Group):** `sheikhs`

**Fields to Index:**
1. `enabled` (Ascending) - Equality filter
2. `createdAt` (Ascending) - Sort order

**Query:** Used to list enabled sheikhs for a subcategory, sorted by creation date.

**How to Create:**

1. **Automatic (Recommended):**
   - Run the app and navigate to any subcategory page
   - The console will log an error with a direct link
   - Click the link to open Firebase Console
   - Click "Create Index" button
   - Wait for index to build (usually 1-5 minutes)

2. **Manual via Firebase Console:**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Navigate to **Firestore Database** → **Indexes** tab
   - Click **Create Index**
   - Select **Collection Group** mode
   - Enter collection ID: `sheikhs`
   - Add fields:
     - Field: `enabled`, Order: **Ascending**
     - Field: `createdAt`, Order: **Ascending**
   - Query scope: **Collection group**
   - Click **Create**

3. **Using Firebase CLI:**
   ```bash
   # Deploy indexes from firestore.indexes.json
   firebase deploy --only firestore:indexes
   ```

#### 2. Chapters Collection (Optional - if using filters)

**Collection Path:** `subcategories/{subcatId}/sheikhs/{sheikhUid}/chapters`

Currently only uses single-field sorting (`order`), which doesn't require a composite index.

#### 3. Lessons Collection (Optional - if using filters)

**Collection Path:** `subcategories/{subcatId}/sheikhs/{sheikhUid}/chapters/{chapterId}/lessons`

Currently only uses single-field sorting (`order`), which doesn't require a composite index.

### Troubleshooting

**Error Message:**
```
يتطلب هذا الاستعلام إنشاء فهرس في قاعدة البيانات
```
(This query requires creating an index in the database)

**Solution:**
1. Check the debug console for the index creation URL
2. Click the URL or follow manual steps above
3. Wait for index to build
4. Tap "إعادة المحاولة" (Retry) button in the app

**Index Build Time:**
- Small datasets: 1-2 minutes
- Medium datasets: 5-10 minutes
- Large datasets: May take longer

**Verify Index Status:**
- Go to Firebase Console → Firestore Database → Indexes
- Check that index status shows "Enabled" (green)
- If status is "Building", wait and refresh periodically

## Offline Caching with SQLite

This app includes a local SQLite caching layer that enables offline reading of lectures, subcategories, and users. Firestore remains the source of truth for all data.

### How It Works

1. **On App Startup:**
   - SQLite database (`local_data.db`) is created/opened in the app's database directory
   - A one-way sync runs from Firestore → SQLite, populating local tables
   - Logs show database path and row counts for each table

2. **Reading Data:**
   - All lecture reads go through `AppRepository` which queries SQLite first (fast, offline-capable)
   - If the device is online, background sync refreshes SQLite from Firestore (non-blocking)
   - UI receives data immediately from SQLite cache

3. **Writing Data:**
   - Writes still go directly to Firestore via `FirebaseService`
   - After a successful write, the record can be upserted into SQLite for immediate local visibility (TODO: implement this optimization)

### Querying from SQLite in UI

The `AppRepository` class provides SQLite-first methods:

```dart
final repository = AppRepository();

// Get lectures by section (SQLite-first, background refresh if online)
final lectures = await repository.getLecturesBySection('الفقه');

// Search lectures locally (offline-capable)
final results = await repository.searchLecturesLocal('search query');

// Get all lectures
final allLectures = await repository.getAllLectures();

// Get subcategories by section
final subcategories = await repository.getSubcategoriesBySection('الفقه');
```

### Database Schema

**Tables:**
- `users` - Cached user profiles
- `subcategories` - Cached subcategory definitions  
- `lectures` - Cached lecture data

**Indexes:**
- `users(email)` - Fast user lookup by email
- `subcategories(section)` - Filter subcategories by section
- `lectures(section)` - Filter lectures by section
- `lectures(sheikhId)` - Filter lectures by sheikh

### Sync Service

The `SyncService` class handles one-way synchronization:

```dart
final syncService = SyncService();

// Sync all collections
await syncService.syncAll();

// Sync individual collections
await syncService.syncUsers();
await syncService.syncSubcategories();
await syncService.syncLectures();

// Optional: Live sync (listens to Firestore changes)
syncService.liveSyncLectures().listen((_) {
  // SQLite updated from Firestore real-time changes
});
```

### Manual Testing

1. **First Run with Internet:**
   - App starts and syncs Firestore → SQLite
   - Check logs for database path and row counts (should be > 0)

2. **Offline Mode:**
   - Turn off internet/airplane mode
   - App should still display lectures from SQLite cache
   - No crashes, data loads instantly

3. **Re-sync After Changes:**
   - Re-enable internet
   - Add/edit a lecture in Firestore Console
   - Re-open app or trigger manual sync
   - SQLite should reflect the changes

### Security Note (TODO)

⚠️ **IMPORTANT:** The current Firebase users collection stores plaintext passwords. This is a security risk. Consider migrating to:
- Firebase Authentication (recommended)
- Or at least hashed passwords (e.g., bcrypt) if custom auth is required

See `lib/database/firebase_service.dart` for current implementation.