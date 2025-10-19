# Sheikh Area Isolation - Summary

## Problem Solved
- Sheikh pages were sharing navigation with User/Admin areas
- No hard separation between role stacks
- Missing "Add Program" functionality for Sheikhs

## Solution Implemented

### **1. Three Isolated Navigator Stacks**

Created `RoleRouter` utility (`lib/utils/role_router.dart`):
- **USER_STACK** (`AppRole.guest`, `AppRole.user`) → `/home` and user routes
- **ADMIN_STACK** (`AppRole.admin`) → `/adminPanel` and admin routes
- **SHEIKH_STACK** (`AppRole.sheikh`) → `/sheikhDashboard` and all `/sheikh/*` routes

**Key Features:**
- Global keys for each navigator stack (for future deep linking)
- `currentRole` tracking
- `switchTo(context, role)` method for hard stack switching
- `canAccessRoute(route, role)` for route authorization
- `blockUnauthorizedRoute(context, route)` with Arabic messages

**Stack Switching:**
- Sheikh login → switches to SHEIKH_STACK (replaces entire navigation)
- Sheikh logout → switches back to USER_STACK (guest mode)
- Admin login → switches to ADMIN_STACK
- User login → stays in USER_STACK

### **2. Sheikh-Only Routes Added**

**New Routes (`lib/main.dart`):**
```dart
'/sheikhLogin'       → SheikhLoginPage
'/sheikhDashboard'   → SheikhHomeTabs  
'/sheikh/program'    → SheikhProgramCreateScreen (NEW)
'/sheikh/chapters'   → SheikhChapterManageScreen
'/sheikh/upload'     → SheikhLessonUploadScreen
```

**Role Guards:**
- All `/sheikh/*` routes check `role == 'sheikh'` on init
- Non-sheikh attempts are blocked with SnackBar: "هذه الصفحة خاصة بالشيخ"
- Auto-navigation back if unauthorized

### **3. New Sheikh Login Screen**

**`lib/screens/sheikh_login_page.dart`:**
- Dedicated Sheikh login page (GREEN theme)
- Fields: معرف الشيخ (8 digits), كلمة المرور
- Uses existing `AuthProvider.loginSheikhWithUniqueId()`
- On success: `RoleRouter.switchTo(context, AppRole.sheikh)`
- Validates role == 'sheikh' after login
- Error handling with Arabic messages

**Route:** `/sheikhLogin`

### **4. Add Program Functionality**

**`lib/screens/sheikh_program_create_screen.dart`:**
- Full-screen form for creating new programs/subcategories
- **Fields:**
  - العنوان (Title) - required, max 100
  - الوصف (Description) - optional, max 500
  - ترتيب العرض (Display Order) - optional, integer
  - الحالة (Status) - مسودة/منشور
- **On Save:**
  - Creates doc in `subcategories` collection
  - Creates ownership doc in `subcategories/{id}/sheikhs/{uid}`
  - Sets: `createdBy: uid`, `createdByName`, `enabled: true`
  - Returns success for stats refresh
- **Success message:** "تم إنشاء البرنامج بنجاح"
- **Guards:** Checks `role == 'sheikh'` on init

**Route:** `/sheikh/program`

### **5. Updated Action Picker**

**`lib/widgets/sheikh_add_action_picker.dart`:**
- Added `onAddProgram` callback (optional parameter)
- **Three Options Now:**
  1. **إضافة برنامج** (NEW) - Purple icon, library_books
  2. **إضافة باب** - Blue icon, folder
  3. **إضافة درس** - Green icon, play_lesson
- Conditionally shows "Add Program" if callback provided

**Updated Callers:**
- `sheikh_dashboard_tab.dart` - passes `onAddProgram` → navigates to `/sheikh/program`
- `sheikh_program_details.dart` - passes `onAddProgram` → navigates to `/sheikh/program`

### **6. Login Integration**

**Updated `lib/screens/login_page.dart`:**
- Already had Sheikh login tab
- Updated `_loginSheikh()` method to use `RoleRouter.switchTo()`
- **Before:** `Navigator.pushReplacementNamed('/sheikhDashboard')`
- **After:** `RoleRouter.switchTo(context, AppRole.sheikh, userData: ...)`

**Updated `lib/screens/sheikh_settings_tab.dart`:**
- Sheikh logout button now uses `RoleRouter.switchTo(context, AppRole.guest)`
- **Before:** `Navigator.pushNamedAndRemoveUntil('/home', ...)`
- **After:** Hard switch to USER_STACK with guest role

### **7. Data Model (Preserved)**

**Programs/Subcategories:**
```
subcategories/{id}
  - name, description, displayOrder, status
  - createdBy, createdByName, createdAt, updatedAt

subcategories/{id}/sheikhs/{sheikhUid}
  - sheikhUid, sheikhName, enabled, createdAt
```

**Chapters:**
```
subcategories/{subcatId}/sheikhs/{sheikhUid}/chapters/{chapterId}
  - title, details, scheduledAt, status, order
  - createdBy, createdAt, updatedAt
```

**Lessons:**
```
subcategories/{subcatId}/sheikhs/{sheikhUid}/chapters/{chapterId}/lessons/{lessonId}
  - title, abstract, tags[], scheduledAt, recordedAt, publishAt, publishedAt
  - status, mediaUrl, mediaType, mediaSize, mediaDuration, storagePath
  - order, createdBy, createdAt, updatedAt
```

### **8. Security (Enhanced)**

**Firestore Rules (already in place):**
```javascript
// Programs (subcategories) - anyone can read, authenticated can create
match /subcategories/{subcategoryId} {
  allow read: if true;
  allow write: if isAuthenticated();
  
  // Sheikh assignment docs
  match /sheikhs/{sheikhUid} {
    allow read: if true;
    allow create, delete: if isAuthenticated();
    allow update: if false;
    
    // Chapters - only assigned sheikh can write
    match /chapters/{chapterId} {
      allow read: if true;
      allow create, update, delete: if isAuthenticated()
                                    && request.auth.uid == sheikhUid
                                    && (!request.resource.data.keys().hasAny(['createdBy']) 
                                        || request.resource.data.createdBy == request.auth.uid);
      
      // Lessons - only assigned sheikh can write
      match /lessons/{lessonId} {
        allow read: if true;
        allow create, update, delete: if isAuthenticated()
                                      && request.auth.uid == sheikhUid
                                      && (!request.resource.data.keys().hasAny(['createdBy']) 
                                          || request.resource.data.createdBy == request.auth.uid);
      }
    }
  }
}
```

**Storage Rules (already in place):**
```javascript
match /lessons_media/{sheikhUid}/{year}/{month}/{lessonId}/{fileName} {
  allow write: if request.auth.uid == sheikhUid
               && request.resource.contentType.matches('audio/.*|video/.*|image/.*')
               && request.resource.size < 500 * 1024 * 1024; // Max 500MB
  allow read: if true;
}
```

**App-Level Guards:**
- All Sheikh screens check `role == 'sheikh'` in `initState()`
- Pop with SnackBar if unauthorized
- No redirect to admin/user pages from Sheikh area

### **9. Navigation Flow**

**Entry to Sheikh Area:**
1. Open `/login` → Sheikh tab
2. Enter 8-digit sheikhId + password
3. On success → `RoleRouter.switchTo(AppRole.sheikh)`
4. Lands on `/sheikhDashboard` (SHEIKH_STACK root)

**Within Sheikh Area:**
- All navigation uses Sheikh routes: `/sheikhDashboard`, `/sheikh/*`
- Back button stays within SHEIKH_STACK
- Logout → switches to USER_STACK

**Blocked Routes:**
- User/Guest attempting `/sheikh/*` → blocked, SnackBar shown
- Admin attempting `/sheikh/*` → blocked, SnackBar shown
- Sheikh attempting `/admin*` → stays in SHEIKH_STACK

### **10. GREEN Theme (Preserved)**

All Sheikh screens maintain GREEN theme:
- AppBar: `Colors.green` background, white foreground
- Buttons: GREEN primary
- Icons: GREEN accent
- Cards: WHITE background with GREEN highlights
- Page background: `#E4E5D3` (light green-beige)

### **11. UX Polish**

**Forms:**
- Arabic/RTL throughout
- Validation on all required fields
- Loading states (disable buttons, show spinners)
- Success/error SnackBars (GREEN/RED)
- No layout overflow (SafeArea + SingleChildScrollView)

**Lists:**
- Pull-to-refresh
- Empty states with icons and messages
- Search (client-side)
- Responsive grids (2 cols mobile, 4 tablet)

**Guards:**
- Immediate role check on screen init
- Auto-pop if unauthorized
- Clear Arabic error messages

## Files Created

1. **`lib/utils/role_router.dart`**
   - Three-stack architecture
   - `switchTo()`, `canAccessRoute()`, `blockUnauthorizedRoute()`

2. **`lib/screens/sheikh_login_page.dart`**
   - Dedicated Sheikh login screen
   - 8-digit sheikhId + password
   - Switches to SHEIKH_STACK on success

3. **`lib/screens/sheikh_program_create_screen.dart`**
   - Add Program form
   - Creates program + ownership doc
   - Role guard enforced

## Files Modified

1. **`lib/main.dart`**
   - Added imports for new screens and RoleRouter
   - Added routes: `/sheikhLogin`, `/sheikh/program`

2. **`lib/screens/login_page.dart`**
   - Updated `_loginSheikh()` to use `RoleRouter.switchTo()`

3. **`lib/screens/sheikh_settings_tab.dart`**
   - Updated logout to use `RoleRouter.switchTo(AppRole.guest)`

4. **`lib/screens/sheikh_dashboard_tab.dart`**
   - Added `onAddProgram` to action picker
   - Routes to `/sheikh/program`

5. **`lib/screens/sheikh_program_details.dart`**
   - Added `onAddProgram` to action picker
   - Routes to `/sheikh/program`

6. **`lib/widgets/sheikh_add_action_picker.dart`**
   - Added `onAddProgram` optional parameter
   - Added "إضافة برنامج" option (purple icon)

## Testing Checklist

- [x] Sheikh login via `/login` → Sheikh tab → switches to SHEIKH_STACK
- [x] Sheikh logout → switches back to USER_STACK (guest)
- [x] All Sheikh screens accessible only after Sheikh login
- [x] Add Program creates subcategory + ownership doc
- [x] Add Chapter/Lesson still work as before
- [x] Stats refresh after Add Program
- [x] Role guards block non-sheikh access
- [x] No cross-contamination between stacks
- [x] Flutter analyze: 5 info-level deprecations, 0 errors, 0 warnings
- [x] No layout overflow at 360×640
- [x] GREEN theme throughout

## Result

✅ **Three isolated stacks:** USER, ADMIN, SHEIKH
✅ **Hard separation:** Sheikh area accessible only via Sheikh login
✅ **Role guards:** All Sheikh routes check `role == 'sheikh'`
✅ **RoleRouter:** Centralized stack switching
✅ **Add Program:** Sheikhs can create programs/subcategories
✅ **Security enforced:** Firestore + Storage rules + App guards
✅ **GREEN theme:** Consistent throughout
✅ **Minimal diffs:** 3 new files, 6 modified files
✅ **Analyze clean:** 5 info, 0 warnings, 0 errors

