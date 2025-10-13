import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class NotificationsPage extends StatelessWidget {
  final Function(bool)? toggleTheme;
  
  const NotificationsPage({super.key, this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: toggleTheme != null ? [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ] : null,
      ),
      drawer: toggleTheme != null ? AppDrawer(toggleTheme: toggleTheme!) : null,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'أوقات الصلاة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          ...[
            'الفجر: 4:45 ص',
            'الظهر: 12:15 م',
            'العصر: 3:45 م',
            'المغرب: 6:30 م',
            'العشاء: 8:00 م'
          ].map((time) => Card(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(time),
                ),
              )),

          const SizedBox(height: 24),
          const Text(
            'أوقات المحاضرات القادمة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          ...[
            'محاضرة الفقه - 4:00 م',
            'محاضرة الحديث - 5:00 م',
          ].map((lecture) => Card(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(lecture),
                ),
              )),

          const SizedBox(height: 24),
          const Text(
            'أحدث المحاضرات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          ...[
            'شرح كتاب التوحيد',
            'سيرة الصحابة - أبو بكر الصديق'
          ].map((lecture) => Card(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.library_books),
                  title: Text(lecture),
                ),
              )),
        ],
      ),
    );
  }
}
