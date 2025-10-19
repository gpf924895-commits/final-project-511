import 'package:flutter/material.dart';
import 'package:new_project/screens/sheikh_programs_tab.dart';
import 'package:new_project/screens/sheikh_lessons_tab.dart';
import 'package:new_project/screens/sheikh_dashboard_tab.dart';
import 'package:new_project/screens/sheikh_settings_tab.dart';

class SheikhHomeTabs extends StatefulWidget {
  const SheikhHomeTabs({super.key});

  @override
  State<SheikhHomeTabs> createState() => _SheikhHomeTabsState();
}

class _SheikhHomeTabsState extends State<SheikhHomeTabs> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    SheikhProgramsTab(),
    SheikhLessonsTab(),
    SheikhDashboardTab(),
    SheikhSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.menu_book,
                  label: 'البرامج',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.play_circle_outline,
                  label: 'الدروس',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'لوحة التحكم',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'الإعدادات',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
