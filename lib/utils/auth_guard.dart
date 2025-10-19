import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/pro_login.dart';

/// Auth guard utility for protecting restricted actions
/// Shows a dialog prompting guest users to log in
class AuthGuard {
  /// Check if user is authenticated, show login dialog if not
  /// Returns true if authenticated, false if guest
  static Future<bool> requireAuth(
    BuildContext context, {
    VoidCallback? onLoginSuccess,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if authenticated (not guest)
    if (authProvider.isAuthenticated) {
      return true;
    }

    // Show login prompt dialog for guest users
    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow tap outside to dismiss
      builder: (BuildContext dialogContext) =>
          _LoginPromptDialog(onLoginSuccess: onLoginSuccess),
    );

    return shouldLogin == true;
  }
}

/// Private dialog widget for login prompt
class _LoginPromptDialog extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const _LoginPromptDialog({this.onLoginSuccess});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pop(true); // Close dialog
    Navigator.pushNamed(context, '/login').then((_) {
      // After returning from login, check if user is now logged in
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn && onLoginSuccess != null) {
        onLoginSuccess?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تسجيل الدخول مطلوب', textAlign: TextAlign.right),
      content: InkWell(
        onTap: () => _navigateToLogin(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'يجب تسجيل الدخول أولاً لإتمام هذه العملية.',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => _navigateToLogin(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('تسجيل الدخول'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.start,
    );
  }
}
