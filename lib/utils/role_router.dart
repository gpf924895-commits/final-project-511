import 'package:flutter/material.dart';
import 'package:new_project/screens/home_page.dart';
import 'package:new_project/screens/Admin_home_page.dart';
import 'package:new_project/screens/sheikh_home_tabs.dart';

enum AppRole { guest, user, admin, sheikh }

class RoleRouter {
  static final GlobalKey<NavigatorState> userNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> adminNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> sheikhNavigatorKey =
      GlobalKey<NavigatorState>();

  static AppRole currentRole = AppRole.guest;

  static void switchTo(
    BuildContext context,
    AppRole role, {
    Map<String, dynamic>? userData,
    void Function(bool)? toggleTheme,
  }) {
    currentRole = role;

    Widget targetScreen;
    switch (role) {
      case AppRole.admin:
        targetScreen = const AdminPanelPage();
      case AppRole.sheikh:
        targetScreen = const SheikhHomeTabs();
      case AppRole.user:
      case AppRole.guest:
        targetScreen = HomePage(toggleTheme: toggleTheme ?? (_) {});
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  static bool canAccessRoute(String route, AppRole role) {
    if (route.startsWith('/sheikh')) {
      return role == AppRole.sheikh;
    }
    if (route.startsWith('/admin')) {
      return role == AppRole.admin;
    }
    return true; // User routes accessible to all
  }

  static void blockUnauthorizedRoute(BuildContext context, String route) {
    String message;
    if (route.startsWith('/sheikh')) {
      message = 'هذه الصفحة خاصة بالشيخ';
    } else if (route.startsWith('/admin')) {
      message = 'هذه الصفحة للمشرف فقط';
    } else {
      message = 'لا يمكن الوصول لهذه الصفحة';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
