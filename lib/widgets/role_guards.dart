import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/home_page.dart';

class SheikhGuard extends StatelessWidget {
  final Widget child;

  const SheikhGuard({super.key, required this.child});

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
        if (authProvider.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(toggleTheme: (isDark) {}),
              ),
            );
          });
          return const SizedBox.shrink();
        }

        // Check if user has sheikh role
        if (authProvider.role != 'sheikh') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('غير مصرح بالدخول'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(toggleTheme: (isDark) {}),
              ),
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

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print(
          '[AdminGuard] ready=${authProvider.isReady} role=${authProvider.role}',
        );

        // Wait for AuthProvider to be ready
        if (!authProvider.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is authenticated
        if (authProvider.currentUser == null) {
          print('[AdminGuard] No user found, redirecting to login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        // Unified admin check: isLoggedIn && role == 'admin' && status == 'active'
        final normalizedRole = (authProvider.role ?? '').toLowerCase();
        final currentUser = authProvider.currentUser;
        final status =
            (currentUser?['status'] as String?)?.toLowerCase() ?? 'active';

        final isAdmin =
            authProvider.isLoggedIn &&
            currentUser != null &&
            normalizedRole == 'admin' &&
            status == 'active';

        print('[AdminGuard] Unified admin check:');
        print('  - isLoggedIn: ${authProvider.isLoggedIn}');
        print('  - currentUser != null: ${currentUser != null}');
        print('  - normalizedRole: $normalizedRole');
        print('  - status: $status');
        print('  - isAdmin result: $isAdmin');

        if (!isAdmin) {
          print(
            '[AdminGuard] User not authorized (role: $normalizedRole, status: $status)',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('هذه الصفحة للمشرف فقط.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushReplacementNamed(context, '/');
          });
          return const SizedBox.shrink();
        }

        // User is authenticated and has admin/supervisor role - render the child
        return child;
      },
    );
  }
}

class SupervisorGuard extends StatelessWidget {
  final Widget child;

  const SupervisorGuard({super.key, required this.child});

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
        if (authProvider.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(toggleTheme: (isDark) {}),
              ),
            );
          });
          return const SizedBox.shrink();
        }

        // Check if user has supervisor role
        if (authProvider.role != 'supervisor') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('غير مصرح بالدخول'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(toggleTheme: (isDark) {}),
              ),
            );
          });
          return const SizedBox.shrink();
        }

        // User is authenticated and has supervisor role - render the child
        return child;
      },
    );
  }
}
