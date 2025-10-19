# Sheikh Authentication & Authorization Implementation

## Overview
This document describes the implementation of authentication and authorization for the Sheikh role interface in the Prophet's Mosque Visitors Platform.

## Key Components

### 1. SplashAuthGate (`lib/screens/splash_auth_gate.dart`)
- **Purpose**: Single entry point that blocks rendering until authentication is resolved
- **Features**:
  - Waits for Firebase initialization
  - Waits for AuthProvider session restoration
  - Fetches current user role before navigation
  - Route decisions based on authentication state:
    - No session → `/login`
    - Role == 'sheikh' → `/sheikh/home`
    - Other roles → `/home`

### 2. SheikhGuard (`lib/widgets/sheikh_guard.dart`)
- **Purpose**: Protects all Sheikh screens with authentication and role checks
- **Features**:
  - Checks if AuthProvider is ready
  - Verifies user authentication
  - Validates sheikh role
  - Redirects unauthorized users with Arabic error messages
  - Provides `SheikhNavigationHelper.goToSheikhArea()` for safe navigation

### 3. Enhanced AuthProvider (`lib/provider/pro_login.dart`)
- **New Features**:
  - `isReady` flag to track initialization status
  - `initialize()` method for session restoration
  - Enhanced login methods that set ready flag
  - Proper role fetching and caching

### 4. Protected Sheikh Screens
All Sheikh screens are wrapped with `SheikhGuard` at the widget level:
- `SheikhHomePage` - Dashboard with stats and action buttons
- `SheikhCategoryPicker` - Category selection for new lectures
- `AddLectureForm` - Form for creating new lectures
- `EditLecturePage` - List and edit existing lectures
- `DeleteLecturePage` - Archive and delete lectures

## Authentication Flow

### Cold Start (No Session)
1. App starts → SplashAuthGate
2. AuthProvider.initialize() → No Firebase user found
3. Navigate to `/login`
4. User logs in → Role fetched and cached
5. Navigate to appropriate dashboard

### Cold Start (Existing Session)
1. App starts → SplashAuthGate
2. AuthProvider.initialize() → Firebase user found
3. Fetch user data from Firestore
4. Cache role information
5. Navigate based on role:
   - Sheikh → `/sheikh/home`
   - Admin → `/admin_panel`
   - Other → `/home`

### Sheikh Screen Access
1. User navigates to any `/sheikh/*` route
2. SheikhGuard checks:
   - AuthProvider.isReady
   - User authentication
   - User role == 'sheikh'
3. If any check fails → Redirect with error message
4. If all checks pass → Render the screen

## Security Features

### Route Protection
- All Sheikh routes are protected at the route level in `main.dart`
- Each Sheikh screen is wrapped with `SheikhGuard` at the widget level
- Double protection ensures no unauthorized access

### Role Validation
- Role is fetched from Firestore during login
- Role is cached in AuthProvider for performance
- Role is validated on every Sheikh screen access

### Error Handling
- Arabic error messages for unauthorized access
- Graceful fallbacks for network issues
- Loading states during authentication checks

## Manual Test Plan

### 1. Cold Start (No Session)
- [ ] Launch app
- [ ] Verify SplashAuthGate shows loading
- [ ] Verify redirect to `/login`
- [ ] No Sheikh UI should be visible

### 2. Cold Start (Sheikh Session)
- [ ] Launch app with existing Sheikh session
- [ ] Verify SplashAuthGate shows loading
- [ ] Verify redirect to `/sheikh/home`
- [ ] Sheikh dashboard should load immediately

### 3. Direct Route Access
- [ ] Try to navigate to `/sheikh/home` without authentication
- [ ] Verify redirect to `/login`
- [ ] Try to navigate to `/sheikh/home` with non-sheikh role
- [ ] Verify redirect to `/home` with error message

### 4. Sheikh Navigation
- [ ] Login as Sheikh
- [ ] Navigate to `/sheikh/home`
- [ ] Verify all Sheikh screens are accessible
- [ ] Verify "إضافة" button works without additional auth checks

### 5. Role Switching
- [ ] Login as Sheikh
- [ ] Navigate to Sheikh dashboard
- [ ] Logout and login as Admin
- [ ] Verify redirect to Admin panel
- [ ] Try to access `/sheikh/home`
- [ ] Verify redirect with error message

## Firestore Security Rules

The following security rules should be implemented in Firestore:

```javascript
// Allow sheikhs to read/write only their own lectures
match /lectures/{lectureId} {
  allow read, write: if request.auth != null 
    && request.auth.uid == resource.data.sheikhId
    && request.auth.token.role == 'sheikh';
}

// Allow sheikhs to create lectures with their own ID
match /lectures/{lectureId} {
  allow create: if request.auth != null 
    && request.auth.uid == request.resource.data.sheikhId
    && request.auth.token.role == 'sheikh';
}
```

## Required Firestore Indexes

```javascript
// Composite index for sheikh lecture queries
{
  "collectionGroup": "lectures",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "sheikhId", "order": "ASCENDING"},
    {"fieldPath": "startTime", "order": "DESCENDING"}
  ]
}
```

## Performance Considerations

- AuthProvider initialization is async but non-blocking
- Role caching prevents repeated Firestore queries
- SheikhGuard checks are lightweight
- Navigation helper prevents unnecessary route attempts

## Error Messages (Arabic)

- "غير مصرح بالدخول" - Unauthorized access
- "جاري التحميل، يرجى المحاولة لاحقاً" - Loading, please try later
- "تعذر الحفظ، حاول لاحقًا" - Save failed, try later

## Files Modified

1. `lib/screens/splash_auth_gate.dart` - New splash screen
2. `lib/widgets/sheikh_guard.dart` - New guard widget
3. `lib/provider/pro_login.dart` - Enhanced with readiness and initialization
4. `lib/main.dart` - Updated routes and initialization
5. `lib/screens/sheikh/*` - All Sheikh screens wrapped with guards

## Dependencies

No new dependencies were added. The implementation uses existing:
- Flutter Provider
- Firebase Auth
- Firebase Firestore
- Navigator 1.0

## Testing

Run the test suite:
```bash
flutter test test/sheikh_auth_guard_test.dart
```

## Rollback Plan

To revert these changes:
1. Remove `lib/screens/splash_auth_gate.dart`
2. Remove `lib/widgets/sheikh_guard.dart`
3. Revert `lib/provider/pro_login.dart` to remove `isReady` and `initialize()`
4. Revert `lib/main.dart` to original initialization
5. Remove SheikhGuard wrappers from all Sheikh screens
6. Delete test file `test/sheikh_auth_guard_test.dart`
