import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_project/repository/local_repository.dart';

class SheikhAuthGuard {
  // _repository not needed - static methods use LocalRepository() directly

  // Validate credentials stored locally
  // This function returns true only when Sheikh is confirmed
  static Future<bool> validateCurrentSheikh(BuildContext context) async {
    try {
      // Check locally first
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('sheikhId') ?? '';
      final storedEmail = prefs.getString('sheikhEmail') ?? '';

      if (storedId.isEmpty || storedEmail.isEmpty) {
        // No cached login — fail
        return false;
      }

      // Verify in LocalRepository
      final repository = LocalRepository();
      final sheikh = await repository.getUserByUniqueId(
        storedId,
        role: 'sheikh',
      );

      if (sheikh == null) return false;
      final data = sheikh;
      if ((data['email'] ?? '').toString() != storedEmail) return false;

      return true;
    } catch (e) {
      // On any error, return false (do not allow navigation)
      return false;
    }
  }

  // Use this helper anywhere you must navigate to Sheikh area
  static Future<bool> validateThenNavigate(
    BuildContext context,
    Future<void> Function() navigate,
  ) async {
    final ok = await validateCurrentSheikh(context);
    if (ok) {
      await navigate();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل دخول الشيخ أولاً')),
      );
      // Optionally route to sheikh login:
      Navigator.pushReplacementNamed(context, '/sheikhLogin');
      return false;
    }
  }
}
