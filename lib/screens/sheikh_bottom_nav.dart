import 'package:flutter/material.dart';
import 'package:new_project/screens/sheikh_home_screen.dart';
import 'package:new_project/screens/sheikh_programs_screen.dart';
import 'package:new_project/screens/sheikh_lessons_screen.dart';
import 'package:new_project/screens/sheikh_chapters_screen.dart';

class SheikhBottomNav extends StatefulWidget {
  const SheikhBottomNav({super.key});

  @override
  State<SheikhBottomNav> createState() => _SheikhBottomNavState();
}

class _SheikhBottomNavState extends State<SheikhBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SheikhHomeScreen(),
    const SheikhProgramsScreen(),
    const SheikhLessonsScreen(),
    const SheikhChaptersScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'لوحة التحكم',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'البرامج',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.play_lesson_outlined),
      activeIcon: Icon(Icons.play_lesson),
      label: 'الدروس',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_outlined),
      activeIcon: Icon(Icons.menu_book),
      label: 'الأبواب',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: _navItems,
        ),
      ),
    );
  }
}

