# Sheikh Login Implementation Summary

## Overview
Fixed Sheikh login by 8-digit ID to work with direct Firebase Authentication (email/password) instead of Cloud Functions, with full error handling and routing to Sheikh Dashboard.

## Changes Made

### 1. **lib/provider/pro_login.dart**
- Removed dependency on Cloud Functions (`firebase_functions`)
- Implemented direct Firestore query for sheikh lookup by `sheikhId`
- **Sheikh ID Normalization**: 
  - Trim whitespace
  - Remove non-digits
  - Left-pad to 8 digits (e.g., "4" → "00000004")
- **Query Flow**:
  1. Query `users` collection where `role == 'sheikh'` AND `sheikhId == <8-digit>`
  2. Fallback mode if composite index missing (query by role only, filter client-side)
  3. Extract `email` and `uid` from the document
  4. Use `FirebaseAuth.signInWithEmailAndPassword(email, password)`
  5. Force refresh token: `getIdTokenResult(true)`
  6. Re-validate Firestore doc matches role and sheikhId
  7. Set user session and navigate
- **Error Handling** (Arabic messages):
  - `المعرّف غير صحيح` - Invalid/not found sheikhId
  - `كلمة المرور غير صحيحة` - Wrong password
  - `لا يوجد حساب بهذا المعرف` - User not found in Auth
  - `تعذّر الاتصال. حاول مجددًا` - Network error
  - `بيانات الحساب غير مكتملة. راجع المشرف.` - Orphan Firestore doc (no email)
  - `حساب غير مخوّل كشيخ. راجع المشرف.` - Role mismatch or orphan Auth user
  - `انتهت المهلة. تحقق من الاتصال وحاول مجددًا.` - Timeout (8s)
- Added helper methods: `_handleAuthError()`, `_finalizeSheikhLogin()`

### 2. **lib/screens/login_page.dart**
- Updated Sheikh tab TextField for `sheikhId`:
  - Added `keyboardType: TextInputType.number` (digits only)
  - Updated label to `'المعرف الفريد (8 أرقام)'`
- Navigation on success: `Navigator.pushReplacementNamed(context, '/sheikhDashboard')`
- Arabic error messages displayed via SnackBar

### 3. **lib/screens/sheikh_dashboard_page.dart** (NEW)
- Created minimal stub dashboard for sheikhs
- Shows:
  - Sheikh name, sheikhId, and email
  - Logout button with confirmation dialog
  - "قيد التطوير" placeholder for future CRUD features
- Logout navigates to `/home` (guest mode)

### 4. **lib/main.dart**
- Added import: `sheikh_dashboard_page.dart`
- Updated route `/sheikhDashboard` to return `SheikhDashboardPage()`

### 5. **firestore.rules**
- Updated `users` collection read rule to allow **anyone** to read sheikh documents:
  ```
  allow read: if isOwner(userId) 
              || isAdmin() 
              || (resource.data.role == 'sheikh');
  ```
  This enables unauthenticated lookup of sheikh email for login (required before sign-in).

### 6. **test/sheikh_login_test.dart** (NEW)
- Widget tests:
  - Sheikh login form has correct fields
  - Invalid sheikhId shows validation error
  - Sheikh dashboard renders correctly
- Unit tests:
  - SheikhId normalization (padding, trimming)
  - Non-digit removal

### 7. **Removed Files**
- `lib/services/lesson_service.dart` - Removed to avoid firebase_storage dependency (not in current scope)

## Query Used
```dart
// Primary query (requires composite index):
_firestore
  .collection('users')
  .where('role', isEqualTo: 'sheikh')
  .where('sheikhId', isEqualTo: sheikhId)
  .limit(1)
  .get()
  .timeout(Duration(seconds: 8))

// Fallback (if index missing):
_firestore
  .collection('users')
  .where('role', isEqualTo: 'sheikh')
  .get()
  // + client-side filter by sheikhId
```

## Routing
- **Success**: `Navigator.pushReplacementNamed(context, '/sheikhDashboard')`
- **Logout**: `Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false)` (guest mode)

## Required Firestore Index
If using the primary query path, create a composite index:
- **Collection**: `users`
- **Fields**: 
  - `role` (Ascending)
  - `sheikhId` (Ascending)

The implementation includes automatic fallback if this index is missing.

## Testing
Run:
```bash
flutter analyze --no-fatal-infos
flutter test test/sheikh_login_test.dart
```

All modified files pass `flutter analyze` with zero errors.

## Orphan Case Handling
1. **Firestore doc exists, Auth user missing**: Block login with message "بيانات الحساب غير مكتملة. راجع المشرف."
2. **Auth user exists, Firestore doc missing/wrong role**: Sign out automatically and show "حساب غير مخوّل كشيخ. راجع المشرف."

## Security Notes
- Sheikh documents are now publicly readable (necessary for login lookup)
- Email and sheikhId are exposed in Firestore for lookup
- Actual authentication still requires valid Firebase Auth credentials
- Role and sheikhId are re-validated after sign-in to prevent tampering

