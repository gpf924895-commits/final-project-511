import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SheikhAuthGuard {
  // Validate credentials stored locally or via a quick Firestore check.
  // This function must return true only when Sheikh is confirmed.
  // It expects the app to save sheikhId & sheikhEmail on a successful login.
  static Future<bool> validateCurrentSheikh(BuildContext context) async {
    try {
      // check locally first
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('sheikhId') ?? '';
      final storedEmail = prefs.getString('sheikhEmail') ?? '';

      if (storedId.isEmpty || storedEmail.isEmpty) {
        // No cached login — fail
        return false;
      }

      // Verify Firestore record still exists and matches cached id/email
      final q = await FirebaseFirestore.instance
          .collection('sheikhs')
          .where('sheikhId', isEqualTo: storedId)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return false;
      final data = q.docs.first.data();
      if ((data['email'] ?? '').toString() != storedEmail) return false;

      // Additional sanity: ensure createdBy/uid match if you use uid linking
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الرجاء تسجيل دخول الشيخ أولاً")));
      // Optionally route to sheikh login:
      Navigator.pushReplacementNamed(context, '/sheikhLogin');
      return false;
    }
  }
}
