import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'change_password_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../widgets/app_drawer.dart';
import '../utils/page_transition.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) toggleTheme;

  const SettingsPage({super.key, required this.toggleTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;

  void _logout() {
    // Call the AuthProvider logout method to clear authentication state
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    
    // Navigate to LoginPage and remove all previous routes
    SmoothPageTransition.navigateAndRemoveUntil(
      context,
      LoginPage(toggleTheme: widget.toggleTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('الإعدادات'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(toggleTheme: widget.toggleTheme),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('الملف الشخصي'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              SmoothPageTransition.navigateTo(
                context,
                ProfilePage(toggleTheme: widget.toggleTheme),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              SmoothPageTransition.navigateTo(
                context,
                const ChangePasswordPage(),
              );
            },
          ),
          SwitchListTile(
            title: const Text('تفعيل الإشعارات'),
            secondary: const Icon(Icons.notifications),
            value: isNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                isNotificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            secondary: const Icon(Icons.dark_mode),
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
              widget.toggleTheme(value);
            },
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('تسجيل الخروج'),
            onTap: _logout,
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('حول التطبيق'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('حول التطبيق'),
                  content: const Text('تطبيق محاضرات المسجد النبوي.\nالإصدار 1.0.0\nجميع الحقوق محفوظة.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تم'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('المساعدة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('المساعدة'),
                  content: const Text('لأي استفسار يرجى التواصل على: \nexample@email.com'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تم'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
