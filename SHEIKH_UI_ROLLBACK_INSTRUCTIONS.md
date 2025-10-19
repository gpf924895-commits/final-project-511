# Sheikh UI Rollback Instructions

## Overview
This document provides step-by-step instructions to rollback the Sheikh UI redesign and restore the previous Sheikh interface design.

## Files to Revert

### 1. Sheikh Home Screen
**File**: `lib/screens/sheikh/sheikh_home_page.dart`

**Changes to Revert:**
- Remove Admin-style layout (statistics card, button layout)
- Restore original Sheikh dashboard design
- Remove Admin color scheme and spacing
- Restore original navigation methods

**Rollback Steps:**
```dart
// Replace the build method with original design
@override
Widget build(BuildContext context) {
  return SheikhGuard(
    routeName: '/sheikh/home',
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          title: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً الشيخ ${authProvider.currentUser?['name'] ?? 'الكريم'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (authProvider.currentUser?['categoryId'] != null)
                    Chip(
                      label: Text(
                        'القسم: ${_getCategoryName(authProvider.currentUser?['categoryId'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: const Color(0xFFC5A300),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                ],
              );
            },
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.mosque),
              onPressed: () {
                // Mosque icon for visual separation from admin
              },
            ),
          ],
        ),
        body: Consumer2<AuthProvider, LectureProvider>(
          builder: (context, authProvider, lectureProvider, child) {
            if (lectureProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (lectureProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      lectureProvider.errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  _buildStatsCard(lectureProvider),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 24),

                  // Recent Lectures
                  _buildRecentLectures(lectureProvider),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
```

### 2. Category Picker Screen
**File**: `lib/screens/sheikh/sheikh_category_picker.dart`

**Changes to Revert:**
- Remove Admin-style header section
- Restore original grid layout
- Remove Admin button styling
- Restore original card design

**Rollback Steps:**
```dart
// Replace the build method with original design
@override
Widget build(BuildContext context) {
  return SheikhGuard(
    routeName: '/sheikh/add/pickCategory',
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          title: const Text('اختيار فئة المحاضرة'),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر فئة المحاضرة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر الفئة المناسبة لمحاضرتك الجديدة',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryCard(
                      context,
                      'الفقه',
                      Icons.mosque,
                      const Color(0xFF2E7D32),
                      'fiqh',
                    ),
                    _buildCategoryCard(
                      context,
                      'السيرة',
                      Icons.person,
                      const Color(0xFF1976D2),
                      'seerah',
                    ),
                    _buildCategoryCard(
                      context,
                      'التفسير',
                      Icons.menu_book,
                      const Color(0xFF7B1FA2),
                      'tafsir',
                    ),
                    _buildCategoryCard(
                      context,
                      'الحديث',
                      Icons.chat,
                      const Color(0xFFD32F2F),
                      'hadith',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 3. Add Lecture Form
**File**: `lib/screens/sheikh/add_lecture_form.dart`

**Changes to Revert:**
- Remove Admin-style form layout
- Restore original form design
- Remove Admin color scheme
- Restore original spacing

### 4. Edit Lecture Page
**File**: `lib/screens/sheikh/edit_lecture_page.dart`

**Changes to Revert:**
- Remove Admin-style list layout
- Restore original edit design
- Remove Admin color scheme
- Restore original navigation

### 5. Delete Lecture Page
**File**: `lib/screens/sheikh/delete_lecture_page.dart`

**Changes to Revert:**
- Remove Admin-style list layout
- Restore original delete design
- Remove Admin color scheme
- Restore original navigation

## Complete Rollback Process

### Step 1: Backup Current State
```bash
# Create backup of current Sheikh screens
cp -r lib/screens/sheikh/ lib/screens/sheikh_backup/
```

### Step 2: Revert Sheikh Home Screen
```bash
# Restore original Sheikh Home Screen
git checkout HEAD~1 -- lib/screens/sheikh/sheikh_home_page.dart
```

### Step 3: Revert Category Picker
```bash
# Restore original Category Picker
git checkout HEAD~1 -- lib/screens/sheikh/sheikh_category_picker.dart
```

### Step 4: Revert Add Lecture Form
```bash
# Restore original Add Lecture Form
git checkout HEAD~1 -- lib/screens/sheikh/add_lecture_form.dart
```

### Step 5: Revert Edit Lecture Page
```bash
# Restore original Edit Lecture Page
git checkout HEAD~1 -- lib/screens/sheikh/edit_lecture_page.dart
```

### Step 6: Revert Delete Lecture Page
```bash
# Restore original Delete Lecture Page
git checkout HEAD~1 -- lib/screens/sheikh/delete_lecture_page.dart
```

### Step 7: Clean Up
```bash
# Remove backup files
rm -rf lib/screens/sheikh_backup/
```

## Manual Rollback (If Git Not Available)

### 1. Sheikh Home Screen Rollback
- Remove Admin-style statistics card
- Remove Admin-style button layout
- Restore original Sheikh dashboard design
- Remove Admin color scheme
- Restore original navigation methods

### 2. Category Picker Rollback
- Remove Admin-style header section
- Restore original grid layout
- Remove Admin button styling
- Restore original card design

### 3. Form Pages Rollback
- Remove Admin-style form layout
- Restore original form design
- Remove Admin color scheme
- Restore original spacing

## Verification After Rollback

### 1. Visual Verification
- [ ] Sheikh Home Screen shows original design
- [ ] Category Picker shows original grid layout
- [ ] Add/Edit/Delete pages show original design
- [ ] No Admin design elements remain

### 2. Functional Verification
- [ ] All Sheikh features work correctly
- [ ] Navigation flows work properly
- [ ] Data loading and display work
- [ ] Authentication and authorization work

### 3. Performance Verification
- [ ] App loads without errors
- [ ] Navigation is smooth
- [ ] No memory leaks
- [ ] No performance issues

## Troubleshooting Rollback Issues

### Common Issues
1. **Layout Problems**: Check if original design files are restored
2. **Navigation Issues**: Verify route definitions are correct
3. **Styling Issues**: Check if original CSS/styling is restored
4. **Functionality Issues**: Verify original methods are restored

### Solutions
1. **Complete Revert**: Use git to revert all changes
2. **Manual Fix**: Manually restore original code
3. **Fresh Install**: Reinstall from clean state
4. **Debug Mode**: Use debug mode to identify issues

## Prevention for Future

### Best Practices
1. **Version Control**: Always use version control
2. **Backup**: Create backups before major changes
3. **Testing**: Test thoroughly before deployment
4. **Documentation**: Document all changes

### Rollback Strategy
1. **Incremental Changes**: Make small, incremental changes
2. **Feature Flags**: Use feature flags for new features
3. **A/B Testing**: Test changes with limited users
4. **Monitoring**: Monitor for issues after deployment

## Contact Information

If rollback issues persist:
- Check git history for original files
- Review documentation for original design
- Contact development team for assistance
- Use debug mode to identify specific issues

## Notes

- Rollback should preserve all Sheikh functionality
- Original design should be fully restored
- No Admin design elements should remain
- All tests should pass after rollback
- Performance should be maintained
