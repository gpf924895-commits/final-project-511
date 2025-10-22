import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/hierarchy_provider.dart';
import 'package:new_project/screens/category_subcategories_page.dart';
import '../widgets/app_drawer.dart';

class SeerahSectionPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool)? toggleTheme;
  const SeerahSectionPage({
    super.key,
    required this.isDarkMode,
    this.toggleTheme,
  });

  @override
  State<SeerahSectionPage> createState() => _SeerahSectionPageState();
}

class _SeerahSectionPageState extends State<SeerahSectionPage> {
  @override
  void initState() {
    super.initState();
    // Set the selected section and load categories
    Future.microtask(() {
      Provider.of<HierarchyProvider>(
        context,
        listen: false,
      ).setSelectedSection('seerah');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFE4E5D3),
      appBar: AppBar(
        title: const Text('قسم السيرة'),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<HierarchyProvider>(
                context,
                listen: false,
              ).setSelectedSection('seerah');
            },
          ),
          if (widget.toggleTheme != null)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
        ],
      ),
      drawer: widget.toggleTheme != null
          ? AppDrawer(toggleTheme: widget.toggleTheme!)
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<HierarchyProvider>(
          context,
          listen: false,
        ).getCategoriesStream('seerah'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل الفئات',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فئات في قسم السيرة',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم عرض الفئات هنا عند إضافتها',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: widget.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 30,
                      child: const Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      category['name'] ?? 'بدون اسم',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: category['description'] != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              category['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategorySubcategoriesPage(
                            section: 'seerah',
                            sectionNameAr: 'السيرة',
                            categoryId: category['id'],
                            categoryName: category['name'],
                            isDarkMode: widget.isDarkMode,
                            toggleTheme: widget.toggleTheme,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'الإشعارات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  IconData _getIconForSubcategory(String? iconName) {
    switch (iconName) {
      case 'mosque':
        return Icons.mosque;
      case 'handshake':
        return Icons.handshake;
      case 'family':
        return Icons.family_restroom;
      case 'book':
        return Icons.menu_book;
      case 'books':
        return Icons.library_books;
      case 'list':
        return Icons.format_list_numbered;
      case 'quran':
        return Icons.menu_book;
      case 'history':
        return Icons.history_edu;
      case 'school':
        return Icons.school;
      case 'location':
        return Icons.location_on;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.category;
    }
  }
}
