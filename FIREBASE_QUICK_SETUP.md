# Firebase Quick Setup Guide

## ✅ What's Already Done

Your app has been successfully migrated from SQLite to Firebase Firestore! Here's what was completed:

1. ✅ Firebase dependencies added to `pubspec.yaml`
2. ✅ `google-services.json` configured for Android
3. ✅ All database operations migrated to Firestore
4. ✅ All screens and providers updated
5. ✅ SQLite dependency removed

## 🚀 Quick Start (3 Steps)

### Step 1: iOS Configuration (5 minutes)

**⚠️ REQUIRED for iOS devices**

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **mohathrahapp**
3. Go to **Project Settings** → **Your apps** → **iOS app**
4. Download `GoogleService-Info.plist`
5. Copy it to: `ios/Runner/GoogleService-Info.plist`

### Step 2: Firestore Database Setup (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Firestore Database**
3. Click **Create Database**
4. Choose:
   - **Start in test mode** (for development)
   - **Location:** Choose closest to your users
5. Click **Enable**

### Step 3: Test Your App

```bash
# Run the app
flutter run
```

**Test these features:**
- ✅ Login with: `admin@admin.com` / `admin123`
- ✅ Create a lecture
- ✅ View lectures
- ✅ Edit a lecture
- ✅ Delete a lecture

## 📊 Firebase Project Details

- **Project ID:** mohathrahapp
- **Project Number:** 704834842875
- **Package Name:** com.mohthrh.final_project

## 🔐 Default Admin Credentials

```
Username: admin
Email: admin@admin.com
Password: admin123
```

**⚠️ IMPORTANT:** Change these credentials in production!

## 🗃️ Firestore Collections

Your app uses 3 main collections:

1. **users** - User accounts and admin status
2. **lectures** - All lecture content
3. **subcategories** - Lecture organization

All collections are automatically created when you first use the app.

## 🔒 Security Rules (IMPORTANT!)

For production, update your Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if true;
      allow update, delete: if request.auth != null && 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
    }
    
    match /lectures/{lectureId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /subcategories/{subcategoryId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 📱 Platform Support

- ✅ **Android** - Fully configured
- ⚠️ **iOS** - Needs `GoogleService-Info.plist` (Step 1)
- ✅ **Offline Mode** - Automatic caching enabled

## 🐛 Common Issues

### Issue: "No Firebase App created"
**Fix:** Already handled in `main.dart`. If you see this, check that `Firebase.initializeApp()` runs before `runApp()`.

### Issue: "google-services.json not found"
**Fix:** File is already at `android/app/google-services.json`. Run `flutter clean` and rebuild.

### Issue: "Permission denied" in Firestore
**Fix:** 
1. Go to Firestore Database → Rules
2. Set to test mode temporarily:
```javascript
allow read, write: if true;
```
3. Update to proper rules before production!

### Issue: App slow on first load
**Reason:** Firestore is loading data from cloud. Subsequent loads use cache and are faster.

## 📚 Data Migration

**Good News:** Since this is a fresh Firebase setup, there's no old data to migrate! 

- Default subcategories are auto-created on first run
- Admin account is auto-created on first run
- Start adding lectures immediately!

## 🔄 What Changed for Users

### Before (SQLite):
- ❌ Data only on one device
- ❌ No backup
- ❌ Can't share between devices

### After (Firebase):
- ✅ Data synced across all devices
- ✅ Automatic cloud backup
- ✅ Works offline with auto-sync
- ✅ Real-time updates (can be enabled)

## 🎯 Next Steps

1. Complete iOS setup (Step 1 above)
2. Enable Firestore database (Step 2 above)
3. Test the app thoroughly
4. Update security rules for production
5. Change admin password
6. Start using your cloud-powered app! 🎉

## 💡 Pro Tips

1. **Backup:** Your data is already backed up in Firebase!
2. **Monitor Usage:** Check Firebase Console → Usage tab
3. **Free Tier:** Firebase free tier is generous for small apps
4. **Offline First:** App works offline and syncs when online

## 📞 Need Help?

Check these resources:
- `FIREBASE_MIGRATION.md` - Detailed technical guide
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)

---

**Ready to go! 🚀**

Your app is now powered by Firebase Firestore cloud database!

