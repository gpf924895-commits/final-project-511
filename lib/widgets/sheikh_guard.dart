import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';

class SheikhGuard extends StatelessWidget {
  final Widget child;
  final String routeName;

  const SheikhGuard({super.key, required this.child, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Wait for AuthProvider to be ready
        if (!authProvider.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is authenticated
        if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          });
          return const SizedBox.shrink();
        }

        // Check if user has sheikh role
        if (authProvider.currentRole != 'sheikh') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('غير مصرح بالدخول'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          });
          return const SizedBox.shrink();
        }

        // User is authenticated and has sheikh role - render the child
        return child;
      },
    );
  }
}

// Helper function to navigate to sheikh area with role check
class SheikhNavigationHelper {
  static void goToSheikhArea(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري التحميل، يرجى المحاولة لاحقاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authProvider.currentRole != 'sheikh') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('غير مصرح بالدخول'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    // User is authenticated and has sheikh role
    Navigator.pushNamed(context, '/sheikh/home');
  }
}
