import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/screens/profile_page.dart';
import 'package:new_project/screens/settings_page.dart';
import 'package:new_project/screens/notifications_page.dart';
import 'package:new_project/screens/login_page.dart';
import '../utils/page_transition.dart';

class AppDrawer extends StatelessWidget {
  final Function(bool) toggleTheme;
  
  const AppDrawer({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF2C2C2C),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF252525) : const Color(0xFF1A1A1A),
            ),
            accountName: Text(
              authProvider.currentUser?['username'] ?? 'مستخدم',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              authProvider.currentUser?['email'] ?? 'guest@example.com',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.green,
              child: authProvider.isLoggedIn
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : const Icon(Icons.person_outline, size: 40, color: Colors.white),
            ),
          ),
          
          // Menu Items
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'ملف الشخصي',
            onTap: () {
              Navigator.pop(context);
              SmoothPageTransition.navigateTo(
                context,
                const ProfilePage(),
              );
            },
          ),
          
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'تمت مشاهدتها مؤخراً',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً: المشاهدات الأخيرة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          
          _buildDrawerItem(
            context,
            icon: Icons.favorite,
            title: 'المفضلة',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً: المحاضرات المفضلة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          
          const Divider(color: Colors.grey),
          
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'الإعدادات والخصوصية',
            onTap: () {
              Navigator.pop(context);
              SmoothPageTransition.navigateTo(
                context,
                SettingsPage(toggleTheme: toggleTheme),
              );
            },
          ),
          
          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'الإشعارات',
            onTap: () {
              Navigator.pop(context);
              SmoothPageTransition.navigateTo(
                context,
                const NotificationsPage(),
              );
            },
          ),
          
          const Divider(color: Colors.grey),
          
          if (!authProvider.isLoggedIn)
            _buildDrawerItem(
              context,
              icon: Icons.login,
              title: 'تسجيل دخول',
              onTap: () {
                Navigator.pop(context);
                SmoothPageTransition.navigateAndReplace(
                  context,
                  LoginPage(toggleTheme: toggleTheme),
                );
              },
            ),
          
          if (authProvider.isLoggedIn)
            _buildDrawerItem(
              context,
              icon: Icons.swap_horiz,
              title: 'تغيير الحساب',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تغيير الحساب'),
                    content: const Text('هل تريد تسجيل الخروج والدخول بحساب آخر؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          authProvider.logout();
                          SmoothPageTransition.navigateAndRemoveUntil(
                            context,
                            LoginPage(toggleTheme: toggleTheme),
                          );
                        },
                        child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          if (authProvider.isLoggedIn)
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, authProvider);
              },
            ),
          
          const SizedBox(height: 20),
          
          // App Info at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 8),
                const Text(
                  'محاضرات المسجد النبوي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.green.withOpacity(0.1),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              SmoothPageTransition.navigateAndRemoveUntil(
                context,
                LoginPage(toggleTheme: toggleTheme),
              );
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

