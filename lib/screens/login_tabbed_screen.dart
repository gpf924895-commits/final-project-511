import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/login_page.dart';
import 'package:new_project/screens/sheikh_login_page.dart';
import 'package:new_project/screens/admin_login_page.dart';

class LoginTabbedScreen extends StatefulWidget {
  final Function(bool) toggleTheme;

  const LoginTabbedScreen({super.key, required this.toggleTheme});

  @override
  State<LoginTabbedScreen> createState() => _LoginTabbedScreenState();
}

class _LoginTabbedScreenState extends State<LoginTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToSupervisorLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLoginPage(),
      ),
    );
  }

  void _handleLoginSuccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Navigate based on role
    if (authProvider.currentRole == 'user') {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else if (authProvider.currentRole == 'sheikh') {
      Navigator.pushNamedAndRemoveUntil(context, '/sheikh/home', (route) => false);
    } else if (authProvider.currentRole == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/admin/home', (route) => false);
    } else if (authProvider.currentRole == 'supervisor') {
      Navigator.pushNamedAndRemoveUntil(context, '/supervisor/home', (route) => false);
    } else {
      // Unknown role - go to GuestHome
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E5D3),
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Supervisor login icon
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _navigateToSupervisorLogin,
            tooltip: 'دخول المشرف',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'مستخدم',
            ),
            Tab(
              icon: Icon(Icons.mosque),
              text: 'شيخ',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // User Login Tab
          LoginPageWrapper(
            toggleTheme: widget.toggleTheme,
            onLoginSuccess: _handleLoginSuccess,
          ),
          // Sheikh Login Tab
          SheikhLoginPageWrapper(
            onLoginSuccess: _handleLoginSuccess,
          ),
        ],
      ),
    );
  }
}

// Wrapper for LoginPage to handle success callback
class LoginPageWrapper extends StatelessWidget {
  final Function(bool) toggleTheme;
  final VoidCallback onLoginSuccess;

  const LoginPageWrapper({
    super.key,
    required this.toggleTheme,
    required this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      toggleTheme: toggleTheme,
      onLoginSuccess: onLoginSuccess,
    );
  }
}

// Wrapper for SheikhLoginPage to handle success callback
class SheikhLoginPageWrapper extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const SheikhLoginPageWrapper({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SheikhLoginPage(
      onLoginSuccess: onLoginSuccess,
    );
  }
}
