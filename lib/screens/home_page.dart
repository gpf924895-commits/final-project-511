import 'package:flutter/material.dart';
import 'fiqh_section.dart';
import 'hadith_section.dart';
import 'tafsir_section.dart';
import 'seerah_section.dart';
import 'notifications_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final Function(bool) toggleTheme;
  const HomePage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'محاضرات',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CategoryIcon(
                        title: 'الحديث',
                        icon: Icons.auto_stories,
                        isDarkMode: isDarkMode),
                    CategoryIcon(
                        title: 'التفسير',
                        icon: Icons.menu_book,
                        isDarkMode: isDarkMode),
                    CategoryIcon(
                        title: 'السيرة',
                        icon: Icons.book,
                        isDarkMode: isDarkMode),
                    CategoryIcon(
                        title: 'الفقه',
                        icon: Icons.library_books,
                        isDarkMode: isDarkMode),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // خريطة المسجد النبوي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خريطة المسجد النبوي',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/map.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // المضافة مؤخرًا
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المضافة مؤخرًا',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.menu_book_outlined),
                        title: Text('المحاضرة الأولى'),
                        subtitle: Text('وصف المحاضرة...'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'الإشعارات'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()));
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        SettingsPage(toggleTheme: widget.toggleTheme)));
          }
        },
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDarkMode;

  const CategoryIcon(
      {Key? key,
      required this.title,
      required this.icon,
      required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'الفقه':
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FiqhSectionPage(isDarkMode: isDarkMode)));
            break;
          case 'الحديث':
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        HadithSectionPage(isDarkMode: isDarkMode)));
            break;
          case 'التفسير':
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        TafsirSectionPage(isDarkMode: isDarkMode)));
            break;
          case 'السيرة':
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        SeerahSectionPage(isDarkMode: isDarkMode)));
            break;
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
