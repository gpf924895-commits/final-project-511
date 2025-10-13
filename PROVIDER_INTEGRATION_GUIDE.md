# Provider Integration Guide

## Overview
This document explains how all pages are connected using Provider to manage lecture state across the application.

## Architecture

### 1. LectureProvider (`lib/provider/lecture_provider.dart`)
The central state management class that handles all lecture-related data and operations.

**Key Features:**
- Manages lectures for all sections (Fiqh, Hadith, Tafsir, Seerah)
- Provides real-time data synchronization across all pages
- Handles loading states and error messages
- Communicates with DatabaseHelper for all database operations

**Main Methods:**
- `loadAllLectures()` - Loads all lectures from database
- `loadLecturesBySection(String section)` - Loads lectures for a specific section
- `loadAllSections()` - Loads all sections at once
- `addLecture()` - Adds a new lecture and refreshes data
- `updateLecture()` - Updates a lecture and refreshes data
- `deleteLecture()` - Deletes a lecture and refreshes data
- `searchLectures(String query)` - Searches lectures by title/description

**Getters:**
- `allLectures` - Returns all lectures
- `fiqhLectures` - Returns Fiqh section lectures
- `hadithLectures` - Returns Hadith section lectures
- `tafsirLectures` - Returns Tafsir section lectures
- `seerahLectures` - Returns Seerah section lectures
- `recentLectures` - Returns the 5 most recent lectures

### 2. Main.dart Integration
The LectureProvider is added to the MultiProvider widget tree:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => AuthProvider()),
    ChangeNotifierProvider(create: (context) => LocationProvider()),
    ChangeNotifierProvider(create: (context) => LectureProvider()),
  ],
  child: const MyApp(),
)
```

This makes the LectureProvider available throughout the entire app.

### 3. Section Pages (Fiqh, Hadith, Tafsir, Seerah)
All section pages follow the same pattern:

**Features:**
- Load lectures specific to their section on page open
- Use `Consumer<LectureProvider>` to listen for data changes
- Display lectures in a list with beautiful cards
- Show loading indicator while fetching data
- Show empty state when no lectures exist
- Refresh button in AppBar to reload data
- Tap on lecture to view full details in a dialog

**Data Flow:**
1. Page opens → `loadLecturesBySection()` is called in `initState()`
2. Provider fetches data from database
3. `Consumer` widget rebuilds when data arrives
4. Lectures are displayed in UI

### 4. Home Page
The home page displays recent lectures from all sections:

**Features:**
- Loads all sections on page open
- Displays up to 5 most recent lectures
- Shows lecture section with color-coded icon
- Refresh button to reload data
- Tap on lecture to view full details
- Empty state when no lectures exist

**Recent Lectures Display:**
- Automatically updates when lectures are added/modified/deleted
- Shows lecture title, description, section, and video indicator
- Color-coded icons for each section

### 5. Admin Panel Integration
The admin panel triggers provider refresh after any lecture operation:

**Add Lecture:**
```dart
if (result == true) {
  _loadStats();
  Provider.of<LectureProvider>(context, listen: false).loadAllSections();
}
```

**Edit/Delete Lecture:**
```dart
.then((_) {
  _loadStats();
  Provider.of<LectureProvider>(context, listen: false).loadAllSections();
});
```

This ensures that:
- Home page shows the latest lectures immediately
- Section pages reflect changes when navigated to
- All data stays synchronized across the app

## Data Flow Diagram

```
Admin Panel (Add/Edit/Delete)
        ↓
Database (SQLite)
        ↓
LectureProvider.loadAllSections()
        ↓
    notifyListeners()
        ↓
┌───────┬────────┬─────────┬─────────┬──────────┐
│       │        │         │         │          │
Home  Fiqh   Hadith  Tafsir  Seerah Section
Page  Section Section Section Section Pages
```

## Benefits of This Architecture

1. **Single Source of Truth**: All lecture data is managed by LectureProvider
2. **Real-time Updates**: Changes propagate automatically to all listening widgets
3. **Efficient**: Only affected widgets rebuild when data changes
4. **Maintainable**: Centralized state management makes debugging easier
5. **Scalable**: Easy to add new features or sections

## Usage Examples

### Accessing Lecture Data
```dart
// In a StatelessWidget
Consumer<LectureProvider>(
  builder: (context, lectureProvider, child) {
    final lectures = lectureProvider.fiqhLectures;
    return ListView.builder(...);
  },
)

// In a StatefulWidget (non-listening)
Provider.of<LectureProvider>(context, listen: false).loadAllSections();
```

### Adding a New Section
1. Add section name to database queries in `app_database.dart`
2. Add section getter and list in `LectureProvider`
3. Create new section page following existing pattern
4. Add section button to home page
5. Add section option to admin panel

## Testing the Integration

1. **Add a lecture** from admin panel
   - Check home page → should appear in "المضافة مؤخرًا"
   - Navigate to section page → should appear in the list

2. **Edit a lecture** from admin panel
   - Changes should reflect in home page and section page

3. **Delete a lecture** from admin panel
   - Should disappear from home page and section page

4. **Navigate between pages**
   - Data should load correctly
   - Refresh buttons should work

## Troubleshooting

**Issue**: Lectures not showing after adding
- **Solution**: Check that provider.loadAllSections() is called after add/edit/delete

**Issue**: Loading indicator stuck
- **Solution**: Check database connection and error messages in console

**Issue**: Duplicate data
- **Solution**: Ensure Consumer widgets are not nested incorrectly

## Future Enhancements

Possible improvements to consider:
- Add pagination for large lecture lists
- Implement search functionality on section pages
- Add filters (by date, video availability, etc.)
- Cache lecture data to reduce database queries
- Add offline support with local storage

