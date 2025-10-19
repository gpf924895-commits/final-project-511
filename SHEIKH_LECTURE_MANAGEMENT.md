# Sheikh Lecture Management System

## Overview
This document describes the new Sheikh lecture management system that allows sheikhs to manage their own lectures within the Prophet's Mosque Visitors Platform.

## Features

### 1. Sheikh Home Dashboard (`/sheikh/home`)
- **Personalized greeting** with sheikh name
- **Section indicator** showing assigned category
- **Statistics card** displaying:
  - Total lectures count
  - Upcoming lectures today
  - Last updated timestamp
- **Action buttons** for:
  - إضافة (Add) - Opens category picker
  - تعديل (Edit) - Opens edit page
  - إزالة (Delete) - Opens delete page
- **Recent lectures list** showing latest 5 lectures

### 2. Category Picker (`/sheikh/add/pickCategory`)
- **Four main categories**:
  - الفقه (Fiqh) - Islamic jurisprudence
  - السيرة (Seerah) - Prophet's biography
  - التفسير (Tafsir) - Quran interpretation
  - الحديث (Hadith) - Prophet's sayings
- **Visual cards** with icons and descriptions
- **Direct navigation** to lecture form with pre-selected category

### 3. Add Lecture Form (`/sheikh/add/form`)
- **Pre-filled data**:
  - Sheikh ID and name from authentication
  - Category key and Arabic name from selection
- **Required fields**:
  - Title (validation required)
  - Start time (date and time picker)
- **Optional fields**:
  - Description
  - End time (with toggle)
  - Location
  - Audio URL (with validation)
  - Video URL (with validation)
- **Validation**:
  - Title is required
  - URL format validation
  - Overlapping time detection
- **Save functionality** with success/error feedback

### 4. Edit Lecture Page (`/sheikh/edit`)
- **Filtered lecture list** showing only sheikh's own lectures
- **Status indicators** (draft, published, archived)
- **Lecture cards** with:
  - Title and category
  - Start time
  - Description preview
  - Status badge
- **Edit form** with all lecture details pre-populated
- **Update functionality** with validation

### 5. Delete Lecture Page (`/sheikh/delete`)
- **Filtered lecture list** excluding deleted lectures
- **Two-step deletion process**:
  1. **Archive first** (soft delete) - sets status to "archived"
  2. **Permanent delete** - sets status to "deleted" with timestamp
- **Confirmation dialogs** with warnings
- **Visual feedback** for different actions

## Data Model

### Firestore Collection: `lectures`
```javascript
{
  sheikhId: string,           // Required - Current sheikh's UID
  sheikhName: string,         // Sheikh's display name
  categoryKey: string,        // "fiqh" | "seerah" | "tafsir" | "hadith"
  categoryNameAr: string,     // Arabic category name
  title: string,              // Required - Lecture title
  description?: string,       // Optional description
  startTime: Timestamp,       // Required - UTC timestamp
  endTime?: Timestamp,        // Optional - UTC timestamp
  location?: {                // Optional location data
    lat?: number,
    lng?: number,
    label?: string
  },
  status: string,             // "draft" | "published" | "archived" | "deleted"
  deletedAt?: Timestamp,      // Set only for permanent deletion
  media?: {                   // Optional media attachments
    audioUrl?: string,
    videoUrl?: string,
    attachments?: Array<{name: string, url: string}>
  },
  createdAt: Timestamp,       // Auto-generated
  updatedAt: Timestamp        // Auto-generated
}
```

## Security & Access Control

### SheikhGuard Widget
- **Authentication check**: Ensures user is logged in
- **Role verification**: Confirms user has 'sheikh' role
- **Automatic redirect**: Sends unauthorized users to home page
- **Error message**: Shows "غير مصرح بالدخول" for unauthorized access

### Data Filtering
- **All queries** include `sheikhId == currentUser.uid`
- **No cross-sheikh access** - sheikhs can only see their own lectures
- **Permission validation** on all CRUD operations

## UI/UX Features

### Design Elements
- **RTL support** enforced throughout
- **Arabic text only** for all user-facing strings
- **Color scheme**:
  - Base: Green (#4CAF50)
  - Accent: Gold (#C5A300) or Olive (#708238)
  - Action colors: Blue (edit), Red (delete), Orange (archive)
- **Icons**: Mosque/minaret for visual separation from admin

### Navigation
- **Breadcrumb navigation** with clear back buttons
- **Success/error feedback** with snackbars
- **Loading states** with progress indicators
- **Empty states** with helpful messages

## Technical Implementation

### Firebase Service Extensions
- `addSheikhLecture()` - Create new lecture with validation
- `getLecturesBySheikh()` - Fetch sheikh's lectures
- `updateSheikhLecture()` - Update with permission check
- `archiveSheikhLecture()` - Soft delete
- `deleteSheikhLecture()` - Permanent delete
- `hasOverlappingLectures()` - Time conflict detection
- `getSheikhLectureStats()` - Dashboard statistics

### Lecture Provider Extensions
- `loadSheikhLectures()` - Load sheikh's lectures
- `addSheikhLecture()` - Add with overlap checking
- `updateSheikhLecture()` - Update with validation
- `archiveSheikhLecture()` - Archive functionality
- `deleteSheikhLecture()` - Permanent deletion
- `clearSheikhData()` - Reset state

### Routes Added
- `/sheikh/home` - Sheikh dashboard
- `/sheikh/add/pickCategory` - Category selection
- `/sheikh/add/form` - Lecture creation form
- `/sheikh/edit` - Lecture editing
- `/sheikh/delete` - Lecture deletion

## Validation Rules

### Input Validation
- **Title**: Required, non-empty
- **Start time**: Required, must be in future
- **End time**: Optional, must be after start time
- **URLs**: Valid URL format if provided
- **Time conflicts**: No overlapping lectures for same sheikh

### Business Rules
- **Time overlap prevention**: System blocks conflicting schedules
- **Archive before delete**: Two-step deletion process
- **Permission enforcement**: All operations verify sheikh ownership
- **Status management**: Proper status transitions (draft → published → archived → deleted)

## Error Handling

### Network Issues
- **Offline detection**: Shows "تعذر الحفظ، حاول لاحقًا"
- **Retry mechanisms**: Automatic retry for failed operations
- **State preservation**: Form data maintained during network issues

### Validation Errors
- **Field-level validation**: Real-time feedback
- **Form-level validation**: Prevents submission of invalid data
- **User-friendly messages**: Arabic error messages

## Testing Checklist

### Manual Testing Steps
1. **Login as Sheikh** → Navigate to `/sheikh/home` → Verify personalized greeting
2. **Add lecture** → Choose category → Fill form → Save → Verify creation
3. **Validation testing** → Try empty title → Verify error message
4. **Time conflict** → Add overlapping lectures → Verify blocking
5. **Edit lecture** → Select lecture → Modify → Save → Verify update
6. **Permission test** → Try editing another sheikh's lecture → Verify denial
7. **Delete process** → Archive first → Verify status change
8. **Permanent delete** → Confirm deletion → Verify removal
9. **Offline testing** → Disconnect network → Try save → Verify error
10. **Navigation** → Test all back buttons and route transitions

### Expected Behaviors
- ✅ Sheikh can only access their own lectures
- ✅ All operations include proper validation
- ✅ Time conflicts are prevented
- ✅ Two-step deletion works correctly
- ✅ UI is fully RTL and Arabic
- ✅ Error messages are user-friendly
- ✅ Loading states are shown appropriately
- ✅ Success feedback is provided

## Rollback Instructions

To revert the sheikh lecture management system:

1. **Delete new files**:
   ```bash
   rm -rf lib/screens/sheikh/
   ```

2. **Remove routes** from `main.dart`:
   - Remove sheikh route imports
   - Remove sheikh route definitions
   - Remove sheikh route cases from SheikhStack

3. **Remove Firebase service methods**:
   - Remove `addSheikhLecture()` and related methods
   - Remove sheikh-specific query methods

4. **Remove Lecture Provider extensions**:
   - Remove sheikh-specific methods
   - Remove sheikh state variables

5. **No core changes required**:
   - AuthProvider remains unchanged
   - Core Firebase service remains unchanged
   - Main app structure remains unchanged

## Future Enhancements

### Potential Improvements
- **Bulk operations**: Select multiple lectures for batch actions
- **Advanced scheduling**: Recurring lectures, series management
- **Media management**: File upload, cloud storage integration
- **Notifications**: Email/SMS alerts for lecture reminders
- **Analytics**: Lecture attendance, engagement metrics
- **Export functionality**: PDF reports, calendar integration
- **Mobile optimization**: Touch-friendly interface improvements
- **Accessibility**: Screen reader support, keyboard navigation

### Performance Optimizations
- **Pagination**: Load lectures in batches
- **Caching**: Local storage for offline access
- **Indexing**: Firestore composite indexes for complex queries
- **Real-time updates**: Live lecture status changes
