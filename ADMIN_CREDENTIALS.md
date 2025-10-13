# Admin Login Credentials

## Default Admin Account

When the app starts for the first time, a default admin account is automatically created:

- **Username:** `admin`
- **Email:** `admin@admin.com`
- **Password:** `admin123`

## How to Login as Admin

1. From the login page, navigate to the Admin Login section
2. Enter the username: `admin`
3. Enter the password: `admin123`
4. Click the login button

## Database Integration

The admin login is now fully integrated with the database:

- Admin accounts must have `is_admin = 1` in the database
- Login can be done using either username OR email
- Only users with admin privileges can access the admin panel

## Creating Additional Admin Accounts

To create additional admin accounts, you can use the database directly or create a function to do so programmatically.

## Security Note

⚠️ **Important:** For production use, please:
1. Change the default admin password
2. Implement proper password hashing (bcrypt, argon2, etc.)
3. Remove or secure the `createAdminAccount` function
4. Consider adding two-factor authentication for admin accounts

## Changes Made

1. **Database (`app_database.dart`):**
   - Updated `loginAdmin` to accept username parameter
   - Admin login now searches by username OR email
   - Added `createAdminAccount` method for creating admin accounts
   - Added `is_admin` flag to the returned admin object

2. **Provider (`pro_login.dart`):**
   - Replaced hardcoded admin credentials with database authentication
   - Admin login now uses `DatabaseHelper.loginAdmin()`
   - Proper error handling and loading states

3. **Main App (`main.dart`):**
   - Added database initialization on app startup
   - Automatically creates default admin account if it doesn't exist
   - Uses `WidgetsFlutterBinding.ensureInitialized()` for async initialization

4. **Mosque Map (`mosque_map_preview.dart`):**
   - Now displays the actual map image from `assets/map.png`
   - Includes fallback gradient if image fails to load
   - Properly connected to `MosqueMapPage` for navigation

5. **Assets (`pubspec.yaml`):**
   - Added assets directory configuration
   - Included map.png, logo.png, and profile.png

## Testing

To test the admin login:
1. Run the app
2. Navigate to Admin Login
3. Use the credentials above
4. You should be successfully logged in and redirected to the admin panel

