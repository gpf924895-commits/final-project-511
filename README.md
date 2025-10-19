# Islamic Learning App

A comprehensive Flutter application for Islamic education with multi-role support including Admin, Sheikh, and Guest users. The app features Firebase integration, interactive maps, prayer times, and a complete lecture management system.

## Features

### 🕌 Core Features
- **Multi-Role Authentication**: Admin, Sheikh, and Guest user roles
- **Interactive Mosque Map**: Google Maps integration with mosque locations
- **Prayer Times**: Accurate prayer time calculations with location services
- **Lecture Management**: Complete CRUD operations for Islamic lectures
- **Chapter & Lesson System**: Organized content structure for sheikhs
- **Guest Mode**: Public access to Islamic content without registration

### 👨‍💼 Admin Features
- Sheikh management and approval system
- User role management
- Content moderation
- Analytics and reporting

### 👨‍🏫 Sheikh Features
- Lecture creation and management
- Chapter and lesson organization
- Content upload and editing
- Dashboard with analytics

### 👤 Guest Features
- Browse Islamic content
- Access to public lectures
- Map-based mosque finder
- Prayer time notifications

## Technology Stack

- **Frontend**: Flutter 3.8.1
- **Backend**: Firebase (Firestore, Authentication, Storage, Functions)
- **Maps**: Google Maps Flutter
- **State Management**: Provider
- **Testing**: Flutter Test Framework

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Firebase project setup
- Google Maps API key

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd new_project
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in `lib/firebase_options.dart`

4. Set up Google Maps:
   - Add your Google Maps API key to platform-specific configuration files

5. Run the application:
```bash
flutter run
```

## Firebase Setup

### Required Firestore Indexes

The application requires specific Firestore indexes for optimal performance:

#### 1. Sheikh List (Admin Panel)
- **Collection**: `users`
- **Fields**: `role` (Ascending), `createdAt` (Descending)

#### 2. Sheikhs Collection
- **Collection Group**: `sheikhs`
- **Fields**: `enabled` (Ascending), `createdAt` (Ascending)

See `FIRESTORE_INDEXES.md` for detailed setup instructions.

## Project Structure

```
lib/
├── database/          # Firebase service layer
├── provider/          # State management providers
├── screens/           # UI screens and pages
├── services/          # Business logic services
├── utils/             # Utility functions and helpers
└── widgets/           # Reusable UI components
```

## Testing

The project includes comprehensive test coverage:
- Unit tests for providers and services
- Widget tests for UI components
- Integration tests for user flows
- Navigation and authentication tests

Run tests with:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

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