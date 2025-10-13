# Subcategory Feature Implementation Guide

## Overview
This feature adds subcategories inside each main section (Fiqh, Hadith, Tafsir, Seerah) to organize and manage lecture content more efficiently. This hierarchical structure provides:

- **Better Content Organization**: Lectures are grouped into relevant subcategories
- **Improved User Experience**: Users can browse subcategories before viewing lectures
- **Flexible Data Management**: Easier to add, edit, and retrieve specific content
- **Scalability**: System can handle large amounts of organized content

## Database Structure

### New Table: `subcategories`
```sql
CREATE TABLE subcategories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  section TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  created_at TEXT NOT NULL
)
```

### Updated Table: `lectures`
- Added column: `subcategory_id INTEGER` (nullable)
- Foreign key relationship to `subcategories` table
- ON DELETE SET NULL (if subcategory is deleted, lecture remains but subcategory_id becomes null)

## Default Subcategories

### Fiqh (الفقه)
1. **العبادات** (Worship) - Prayer, fasting, zakat, hajj
2. **المعاملات** (Transactions) - Trade, contracts, financial dealings
3. **الأحوال الشخصية** (Personal Status) - Marriage, divorce, inheritance

### Hadith (الحديث)
1. **الصحيحان** (The Two Sahihs) - Bukhari and Muslim
2. **السنن الأربعة** (The Four Sunan) - Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah
3. **الأربعين النووية** (An-Nawawi's Forty) - Commentary on the forty hadiths

### Tafsir (التفسير)
1. **تفسير القرآن الكريم** (Quran Interpretation) - Tafsir of surahs and verses
2. **أسباب النزول** (Reasons for Revelation) - Stories and contexts of revelation
3. **علوم القرآن** (Quranic Sciences) - Abrogating/abrogated, clear/ambiguous

### Seerah (السيرة)
1. **السيرة المكية** (Meccan Period) - Prophet's life in Mecca
2. **السيرة المدنية** (Medinan Period) - Prophet's life in Medina
3. **الغزوات** (Military Expeditions) - Prophet's battles

## File Changes

### 1. Database (`lib/database/app_database.dart`)
- Updated database version from 2 to 3
- Added `_insertDefaultSubcategories()` method
- Added CRUD methods for subcategories:
  - `getSubcategoriesBySection()`
  - `getSubcategory()`
  - `addSubcategory()`
  - `updateSubcategory()`
  - `deleteSubcategory()`
- Updated `addLecture()` to accept `subcategoryId`
- Updated `updateLecture()` to accept `subcategoryId`
- Added `getLecturesBySubcategory()` method

### 2. Providers

#### New: `lib/provider/subcategory_provider.dart`
- Manages subcategory state across the app
- Methods:
  - `loadSubcategoriesBySection()`
  - `loadAllSubcategories()`
  - `addSubcategory()`
  - `updateSubcategory()`
  - `deleteSubcategory()`
  - `getSubcategoriesBySection()`

#### Updated: `lib/provider/lecture_provider.dart`
- Added `loadLecturesBySubcategory()` method
- Updated `addLecture()` to include subcategoryId parameter
- Updated `updateLecture()` to include subcategoryId parameter

### 3. New Screen: `lib/screens/subcategory_lectures_page.dart`
- Displays lectures for a specific subcategory
- Shows lecture details with icons based on section
- Supports dark mode
- Navigate back to home or subcategories list

### 4. Updated Section Pages
All section pages updated to show subcategories first:
- `lib/screens/fiqh_section.dart`
- `lib/screens/hadith_section.dart`
- `lib/screens/tafsir_section.dart`
- `lib/screens/seerah_section.dart`

**Changes:**
- Load subcategories instead of lectures on page open
- Display subcategories as cards with icons and descriptions
- Navigate to `SubcategoryLecturesPage` when subcategory is tapped
- Added `_getIconForSubcategory()` helper method for icon mapping

### 5. Updated Admin Pages

#### `lib/screens/add_lecture_page.dart`
- Added subcategory dropdown selection (optional)
- Loads subcategories based on selected section
- Passes subcategory ID when creating lecture

#### `lib/screens/Edit_Lecture_Page.dart`
- Added subcategory dropdown in edit dialog
- Shows current subcategory if exists
- Updates subcategory when saving changes

### 6. Main App (`lib/main.dart`)
- Added `SubcategoryProvider` to MultiProvider
- Import: `import 'package:new_project/provider/subcategory_provider.dart';`

## User Flow

### For Regular Users:
1. Open section (e.g., Fiqh)
2. View list of subcategories
3. Select a subcategory
4. View lectures within that subcategory
5. Tap lecture to see details

### For Admins:
1. **Add Lecture:**
   - Select section
   - Optionally select subcategory from dropdown
   - Fill in lecture details
   - Save

2. **Edit Lecture:**
   - View lectures list
   - Tap edit on a lecture
   - Update title, description, video, or subcategory
   - Save changes

## Icon Mapping

Icons are mapped based on `icon_name` field in database:
- `mosque` → Icons.mosque
- `handshake` → Icons.handshake
- `family` → Icons.family_restroom
- `book` → Icons.menu_book
- `books` → Icons.library_books
- `list` → Icons.format_list_numbered
- `quran` → Icons.menu_book
- `history` → Icons.history_edu
- `school` → Icons.school
- `location` → Icons.location_on
- `flag` → Icons.flag
- Default → Icons.category

## Benefits

1. **Organized Content**: Lectures are categorized logically
2. **Easier Navigation**: Users can quickly find relevant content
3. **Scalable**: Can handle hundreds of lectures without clutter
4. **Flexible**: Subcategories can be added, edited, or removed
5. **Backward Compatible**: Existing lectures without subcategories still work
6. **Admin Friendly**: Simple dropdown selection when managing lectures

## Database Migration

When users update the app:
- Database automatically upgrades from version 2 to 3
- `subcategories` table is created
- `subcategory_id` column is added to `lectures` table
- Default subcategories are inserted
- Existing lectures remain unaffected (subcategory_id is NULL)

## Future Enhancements

Possible improvements:
1. Allow admins to create custom subcategories from UI
2. Add subcategory management page (add/edit/delete subcategories)
3. Display lecture count for each subcategory
4. Add search within subcategories
5. Add sorting options (by name, date, etc.)
6. Add subcategory images/banners
7. Allow multiple subcategories per lecture (many-to-many relationship)

## Testing Recommendations

1. Test database migration from version 2 to 3
2. Verify all default subcategories are created
3. Test adding lectures with and without subcategories
4. Test editing lecture subcategories
5. Verify navigation flow: Section → Subcategory → Lectures
6. Test empty states (no subcategories, no lectures)
7. Test dark mode compatibility
8. Test with existing data

## Notes

- Subcategory assignment is **optional** for lectures
- Deleting a subcategory sets `subcategory_id` to NULL for associated lectures
- Subcategories are section-specific (cannot be shared across sections)
- The feature is fully integrated with existing Provider architecture
- All text is in Arabic to match app language

