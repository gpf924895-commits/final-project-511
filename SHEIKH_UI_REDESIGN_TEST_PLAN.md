# Sheikh UI Redesign - Test Plan

## Overview
This document outlines the test plan for verifying that the Sheikh UI has been successfully redesigned to match the Admin design exactly while maintaining Sheikh-specific functionality.

## Visual Verification Checklist

### 1. Sheikh Home Screen (`/sheikh/home`)
**Layout Comparison with Admin:**
- [ ] AppBar has same height, green background, white text
- [ ] Title shows "مرحباً الشيخ <الاسم>" with mosque icon
- [ ] Category chip shows "القسم: <القسم المعين>" in gold color
- [ ] Statistics card has identical design (green background, border, padding)
- [ ] Three main buttons have identical styling:
  - [ ] Green "إضافة" button (same size, shape, elevation)
  - [ ] Blue "تعديل" button (same size, shape, elevation)  
  - [ ] Red "إزالة" button (same size, shape, elevation)
- [ ] Button spacing matches Admin (16px between buttons)
- [ ] Bottom info section shows "مسجل دخول كشيخ: <email>"
- [ ] Refresh and logout buttons in AppBar actions

### 2. Category Picker Screen (`/sheikh/add/pickCategory`)
**Layout Verification:**
- [ ] AppBar matches Admin style (green, centered title)
- [ ] Header section with green background and border
- [ ] Four category buttons with proper styling:
  - [ ] الفقه (green, mosque icon)
  - [ ] السيرة (blue, person icon)
  - [ ] التفسير (purple, book icon)
  - [ ] الحديث (red, chat icon)
- [ ] Each button shows title and description
- [ ] Button height and spacing match Admin button style

### 3. Add Lecture Form (`/sheikh/add/form`)
**Form Layout:**
- [ ] AppBar with green background and "حفظ" action button
- [ ] Category info card at top (green background)
- [ ] Form sections with proper spacing and styling
- [ ] All input fields have consistent styling
- [ ] Error messages display in red containers

### 4. Edit Lecture Page (`/sheikh/edit`)
**List Layout:**
- [ ] AppBar with blue background and centered title
- [ ] Loading state shows CircularProgressIndicator
- [ ] Empty state shows appropriate message
- [ ] Lecture cards have consistent styling
- [ ] Each card shows status, title, category, time
- [ ] Tap to edit functionality works

### 5. Delete Lecture Page (`/sheikh/delete`)
**List Layout:**
- [ ] AppBar with red background and centered title
- [ ] Loading state shows CircularProgressIndicator
- [ ] Empty state shows appropriate message
- [ ] Lecture cards with delete actions
- [ ] Archive and permanent delete options

## Functional Testing

### Authentication & Authorization
- [ ] SheikhGuard blocks unauthorized access
- [ ] Only sheikh role can access Sheikh screens
- [ ] Proper error messages in Arabic
- [ ] Navigation redirects work correctly

### Data Operations
- [ ] Statistics load correctly (total lectures, upcoming today)
- [ ] Add lecture: Category picker → Form → Save
- [ ] Edit lecture: List → Form → Update
- [ ] Delete lecture: List → Archive/Delete → Confirm
- [ ] All operations filtered by sheikhId

### Navigation Flow
- [ ] Sheikh Home → Category Picker → Add Form
- [ ] Sheikh Home → Edit Page → Edit Form
- [ ] Sheikh Home → Delete Page → Archive/Delete
- [ ] Back navigation works correctly
- [ ] Logout returns to home page

## UI Consistency Checks

### Color Scheme
- [ ] Green primary color matches Admin
- [ ] Blue for edit operations
- [ ] Red for delete operations
- [ ] Gold accent for Sheikh-specific elements
- [ ] Consistent background color (0xFFE4E5D3)

### Typography
- [ ] Arabic text displays correctly (RTL)
- [ ] Font sizes match Admin design
- [ ] Font weights are consistent
- [ ] Text alignment is proper

### Spacing & Layout
- [ ] Padding matches Admin (24px for main content)
- [ ] Button heights match Admin (48px minimum)
- [ ] Card corner radius matches Admin (12px)
- [ ] Consistent spacing between elements

### Icons & Visual Elements
- [ ] Mosque icon for Sheikh identification
- [ ] Category icons are appropriate
- [ ] Status indicators work correctly
- [ ] Loading states are consistent

## Performance Testing

### Loading States
- [ ] Initial load shows loading indicator
- [ ] Data loads without flickering
- [ ] Error states display properly
- [ ] Refresh functionality works

### Memory & Performance
- [ ] No memory leaks in navigation
- [ ] Smooth transitions between screens
- [ ] Proper disposal of controllers
- [ ] Efficient data loading

## Accessibility Testing

### RTL Support
- [ ] All text displays right-to-left
- [ ] Layout adapts to RTL direction
- [ ] Icons and buttons align correctly
- [ ] Navigation flows properly

### User Experience
- [ ] Clear visual hierarchy
- [ ] Intuitive navigation
- [ ] Consistent interaction patterns
- [ ] Appropriate feedback for actions

## Cross-Platform Testing

### Android
- [ ] Layout renders correctly
- [ ] Touch interactions work
- [ ] Keyboard navigation works
- [ ] Performance is smooth

### iOS
- [ ] Layout renders correctly
- [ ] Touch interactions work
- [ ] Keyboard navigation works
- [ ] Performance is smooth

### Web
- [ ] Layout adapts to screen size
- [ ] Mouse interactions work
- [ ] Keyboard navigation works
- [ ] Performance is acceptable

## Regression Testing

### Admin Screen Verification
- [ ] Admin screen still works correctly
- [ ] Admin layout unchanged
- [ ] Admin functionality preserved
- [ ] No visual regressions

### Existing Features
- [ ] Guest mode still works
- [ ] Login/logout flows work
- [ ] Other user roles unaffected
- [ ] Navigation between roles works

## Test Execution Steps

1. **Setup**
   - Launch app in debug mode
   - Clear app data if needed
   - Ensure Firebase connection

2. **Authentication Test**
   - Login as Sheikh
   - Verify redirect to `/sheikh/home`
   - Check authentication state

3. **Visual Verification**
   - Compare Sheikh Home with Admin Home
   - Verify layout matches exactly
   - Check color scheme and typography

4. **Functional Testing**
   - Test each button navigation
   - Verify data loading and display
   - Test form submissions
   - Check error handling

5. **Navigation Testing**
   - Test all navigation paths
   - Verify back button behavior
   - Check deep linking
   - Test logout flow

6. **Performance Testing**
   - Monitor memory usage
   - Check loading times
   - Test with large datasets
   - Verify smooth animations

## Success Criteria

✅ **Visual Match**: Sheikh UI matches Admin design exactly
✅ **Functionality**: All Sheikh features work correctly
✅ **Performance**: Smooth operation without lag
✅ **Accessibility**: Proper RTL support and navigation
✅ **Regression**: Admin screen unchanged
✅ **Cross-Platform**: Works on all target platforms

## Issues to Watch For

- Layout inconsistencies with Admin
- Missing Sheikh-specific elements
- Navigation flow problems
- Performance issues
- RTL display problems
- Authentication bypass
- Data filtering issues

## Rollback Plan

If issues are found, rollback steps:
1. Revert Sheikh Home Screen to previous design
2. Revert Category Picker to previous design
3. Revert Add/Edit/Delete pages to previous design
4. Remove any Admin design elements
5. Restore original Sheikh styling
6. Test to ensure functionality is preserved
