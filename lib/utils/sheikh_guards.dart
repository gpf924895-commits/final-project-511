import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'dart:developer' as developer;

class SheikhGuards {
  /// The four allowed categories for Sheikhs
  static const List<String> allowedCategories = [
    "الفقه",
    "السيرة",
    "التفسير",
    "الحديث",
  ];

  /// Check if current user is a Sheikh with permission for a specific category
  /// Returns true if authorized, false otherwise
  /// Shows SnackBar with error message if not authorized
  static bool ensureSheikhWithCategory(
    BuildContext context,
    String subcatId, {
    bool showError = true,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in
    if (!authProvider.isAuthenticated) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
        );
      }
      return false;
    }

    // Check if user is a Sheikh
    if (authProvider.currentRole != 'sheikh') {
      if (showError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('هذه الصفحة خاصة بالشيخ')));
      }
      return false;
    }

    // Check if Sheikh has allowedCategories
    final allowedCategories =
        authProvider.currentUser?['allowedCategories'] as List<dynamic>?;
    if (allowedCategories == null || allowedCategories.isEmpty) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم تعيين أقسام لك بعد')),
        );
      }
      return false;
    }

    // Convert to List<String> and check if subcatId is in allowed categories
    final allowedCategoriesList = allowedCategories.cast<String>();
    if (!allowedCategoriesList.contains(subcatId)) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ليست لديك صلاحية على هذا القسم')),
        );
      }
      return false;
    }

    return true;
  }

  /// Check if current user is a Sheikh (without category check)
  static bool ensureSheikh(BuildContext context, {bool showError = true}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
        );
      }
      return false;
    }

    if (authProvider.currentRole != 'sheikh') {
      if (showError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('هذه الصفحة خاصة بالشيخ')));
      }
      return false;
    }

    return true;
  }

  /// Get allowed categories for current Sheikh
  static List<String> getAllowedCategories(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final allowedCategories =
        authProvider.currentUser?['allowedCategories'] as List<dynamic>?;

    if (allowedCategories == null || allowedCategories.isEmpty) {
      return [];
    }

    return allowedCategories.cast<String>();
  }

  /// Check if Sheikh has any allowed categories
  static bool hasAllowedCategories(BuildContext context) {
    return getAllowedCategories(context).isNotEmpty;
  }

  /// Validate that a category is in the allowed list
  static bool isValidCategory(String category) {
    return allowedCategories.contains(category);
  }

  /// Check if current user owns a resource (createdBy matches current uid)
  static bool isResourceOwner(BuildContext context, String? createdBy) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return createdBy == authProvider.currentUid;
  }

  /// Check if current user can edit/delete a resource
  static bool canModifyResource(BuildContext context, String? createdBy) {
    return ensureSheikh(context, showError: false) &&
        isResourceOwner(context, createdBy);
  }

  /// Show blocking screen for unauthorized category access
  static Widget buildBlockingScreen(BuildContext context, String category) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غير مخول'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                'ليست لديك صلاحية على هذا القسم',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'القسم: $category',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Log security violations for monitoring
  static void logSecurityViolation(String action, String details) {
    developer.log(
      'SECURITY VIOLATION: $action - $details',
      name: 'SheikhGuards',
      level: 1000, // Error level
    );
  }
}
