# Guest Mode Implementation Summary

## Overview
Implemented automatic Guest Mode that allows users to browse the app without authentication. Restricted actions trigger a login prompt dialog, and after successful login, the app resumes the intended action.

## Changes Made

### 1. AuthProvider (`lib/provider/pro_login.dart`)
**Added:**
- `_isGuest` field (default: `true`)
- `isGuest` getter
- `isAuthenticated` getter (returns `true` only if `isLoggedIn && !isGuest`)
- `enterGuestMode()` method to initialize guest state
- `signOutToGuest()` method for returning to guest mode

**Modified:**
- All login methods now set `_isGuest = false` on success
- All login methods return to guest mode (`_isGuest = true`) on error
- `signOut()` now calls `enterGuestMode()` to return to guest mode
- `logout()` now delegates to `enterGuestMode()`

### 2. Main App (`lib/main.dart`)
**Modified:**
- App now always shows `HomePage` by default (guest mode)
- Authenticated users are routed based on role:
  - `role == 'sheikh'` → `AdminPanelPage`
  - `role == 'user'` → `HomePage`
- Guest users see `HomePage` with guest mode indicator

### 3. Auth Guard (`lib/utils/auth_guard.dart`)
**Modified:**
- `requireAuth()` now checks `authProvider.isAuthenticated` instead of `isLoggedIn`
- Dialog allows tapping message body OR primary button to navigate to `/login`
- Preserves `onLoginSuccess` callback for resuming pending actions

### 4. Home Page (`lib/screens/home_page.dart`)
**Modified:**
- Added import for `AuthProvider`
- AppBar now shows "وضع الضيف" badge when `authProvider.isGuest == true`

### 5. Login Page (`lib/screens/login_page.dart`)
**Added:**
- "تصفح كضيف" (Browse as Guest) button at bottom
- Button calls `enterGuestMode()` and routes to `/home`

**Modified:**
- Wrapped `TabBarView` in `Column` with `Expanded` to accommodate guest button

### 6. App Drawer (`lib/widgets/app_drawer.dart`)
**Modified:**
- Header shows "وضع الضيف" and "تصفح بدون حساب" for guest users
- Avatar color changes to grey for guests
- Profile, History, and Favorites items now use `AuthGuard.requireAuth`
- "تسجيل دخول" button shown only for guests (`authProvider.isGuest`)
- "تغيير الحساب" and "تسجيل الخروج" shown only for authenticated users
- Logout now routes to `/home` (guest mode) instead of `/login`

### 7. Settings Page (`lib/screens/settings_page.dart`)
**Modified:**
- Logout now calls `authProvider.signOut()` instead of `logout()`
- Routes to `/home` (guest mode) instead of `/login`

### 8. Admin Home Page (`lib/screens/Admin_home_page.dart`)
**Modified:**
- Logout now calls `authProvider.signOut()` instead of `logout()`
- Routes to `/home` (guest mode) instead of `/login`

### 9. Firestore Rules (`firestore.rules`)
**Updated:**
- Only allow `role: 'user'` creation from client
- Block client-side sheikh creation (only via Cloud Functions)
- Deny changes to `role`, `uniqueId`, `passwordHash` fields on update
- Deny client-side deletes (only server/admin can delete)

### 10. Tests
**Created:**
- `test/guest_mode_test.dart` - Widget tests for guest mode functionality (Note: Firebase initialization required for full execution)
- `test/guest_mode_unit_test.dart` - Unit tests verifying guest mode implementation

## Behavior

### Launch
- App launches directly in **Guest Mode**
- No forced login screen
- Users can browse all public content immediately

### Guest Mode Indicator
- AppBar shows "وضع الضيف" badge
- Drawer shows "وضع الضيف" with "تصفح بدون حساب"
- Grey avatar icon for guests

### Restricted Actions
When a guest triggers a restricted action (profile, history, favorites):
1. Auth guard shows dialog with message: "يجب تسجيل الدخول أولاً لإتمام هذه العملية."
2. Tapping message body OR "تسجيل الدخول" button → navigates to `/login`
3. Tapping "إلغاء" or outside dialog → dismisses
4. After successful login → pending action resumes via `onLoginSuccess` callback

### Login Flow
- User login (email/password) → routes to `/home`
- Sheikh login (uniqueId/password) → routes to `/sheikhDashboard`
- "تصفح كضيف" button → returns to `/home` in guest mode

### Logout Flow
- Logout calls `signOut()` → enters guest mode
- Routes to `/home` (not `/login`)
- User sees guest mode indicator

### Role Routing
- **Guest**: `HomePage` with guest indicator
- **Authenticated User (role: 'user')**: `HomePage` without guest indicator
- **Authenticated Sheikh (role: 'sheikh')**: `AdminPanelPage`

## Security

### Firestore Rules
```firestore
// Only 'user' role allowed from client
allow create: if isOwner(userId)
              && request.resource.data.role == 'user'
              && (!request.resource.data.keys().hasAny(['is_admin', 'uniqueId', 'passwordHash']));

// No role changes allowed
allow update: if isOwner(userId)
              && request.resource.data.role == resource.data.role
              && (!request.resource.data.keys().hasAny(['is_admin', 'uniqueId', 'passwordHash']));
```

### Client Protection
- Sheikh accounts can only be created via Cloud Functions
- Role changes blocked on client
- Sensitive fields (`uniqueId`, `passwordHash`) cannot be set/modified from client

## Testing

### Verification
```bash
flutter analyze  # 0 errors (75 info/warnings - pre-existing)
flutter test test/guest_mode_unit_test.dart  # Passes
```

### Manual Testing Checklist
- [ ] App launches in guest mode
- [ ] "وضع الضيف" indicator visible in AppBar and drawer
- [ ] Can browse lectures, prayer times, map
- [ ] Tapping profile shows login dialog
- [ ] Tapping message body navigates to login
- [ ] After login, profile opens automatically
- [ ] Logout returns to guest mode
- [ ] "تصفح كضيف" button works on login page

## Files Modified
1. `lib/provider/pro_login.dart`
2. `lib/main.dart`
3. `lib/utils/auth_guard.dart`
4. `lib/screens/home_page.dart`
5. `lib/screens/login_page.dart`
6. `lib/widgets/app_drawer.dart`
7. `lib/screens/settings_page.dart`
8. `lib/screens/Admin_home_page.dart`
9. `firestore.rules`

## Files Created
1. `test/guest_mode_test.dart`
2. `test/guest_mode_unit_test.dart`
3. `GUEST_MODE_IMPLEMENTATION.md` (this file)

## Notes
- No new dependencies added
- All user-facing messages in Arabic (RTL)
- Existing functionality preserved
- Zero linter errors
- Guest mode is opt-out (users can login anytime)
- Logout returns to guest mode (not forced re-login)

