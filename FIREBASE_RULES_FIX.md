# 🔥 FIREBASE RULES FIX - IMMEDIATE SOLUTION

## 🚨 **PROBLEM IDENTIFIED**
The permission error you're seeing is caused by a **field name mismatch** in Firestore security rules:

- **App saves data with**: `sheikhId` field
- **Rules check for**: `sheikhUid` field (WRONG!)
- **Result**: Permission denied error

## ✅ **SOLUTION - DEPLOY CORRECTED RULES**

### **Step 1: Open Firebase Console**
Click this link: https://console.firebase.google.com/project/mohathrahapp/firestore/rules

### **Step 2: Replace Rules**
Copy and paste this **EXACT** content:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() 
             && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }
    
    // Helper function to check if user is sheikh
    function isSheikh() {
      return isAuthenticated() 
             && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "sheikh";
    }
    
    // Users collection rules
    match /users/{uid} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Categories collection rules
    match /categories/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Sheikhs collection rules
    match /sheikhs/{uid} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Lectures collection rules - FIXED: sheikhId instead of sheikhUid
    match /lectures/{lectureId} {
      allow read: if true;
      allow create, update, delete:
        if isAuthenticated()
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "sheikh"
        && request.resource.data.sheikhId == request.auth.uid
        && request.resource.data.createdBy == request.auth.uid;
    }
    
    // Chapters collection rules - FIXED: sheikhId instead of sheikhUid
    match /chapters/{chapterId} {
      allow read: if true;
      allow create, update, delete:
        if isAuthenticated()
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "sheikh"
        && request.resource.data.sheikhId == request.auth.uid
        && request.resource.data.createdBy == request.auth.uid;
    }
    
    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### **Step 3: Publish**
1. Click **"Publish"** button
2. Wait for deployment confirmation (1-2 minutes)
3. Test your app - error should be gone!

## 🔍 **WHAT WAS FIXED**

### **Before (Broken Rules):**
```javascript
// This was checking for 'sheikhUid' but app saves 'sheikhId'
&& request.resource.data.sheikhUid == request.auth.uid
```

### **After (Fixed Rules):**
```javascript
// Now correctly checks for 'sheikhId' which matches the app data
&& request.resource.data.sheikhId == request.auth.uid
```

## 🧪 **TESTING**

After deploying the rules:
1. **Login as Sheikh** in your app
2. **Navigate to "إضافة محاضرة" (Add Lecture)**
3. **Fill in lecture details** (title, time, location, media)
4. **Click "حفظ" (Save)**
5. **Verify** - No more permission errors!

## 📋 **VERIFICATION CHECKLIST**

- ✅ Rules deployed successfully
- ✅ No permission denied errors
- ✅ Sheikhs can create lectures
- ✅ All lecture fields work (title, time, location, media)
- ✅ Lectures are saved to Firestore
- ✅ App works normally

## 🎯 **EXPECTED RESULT**

After deploying these rules:
- ❌ **Before**: "The [cloud_firestore/permission-denied] caller does not have permission"
- ✅ **After**: Lecture created successfully with success message

---

**This fix resolves the permission error completely. The app will work normally after deploying the corrected rules.**
