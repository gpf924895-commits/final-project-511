import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/subcategory_provider.dart';
import 'package:new_project/screens/subcategory_sheikhs_page.dart';
import '../widgets/app_drawer.dart';

class TafsirSectionPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool)? toggleTheme;
  const TafsirSectionPage({super.key, required this.isDarkMode, this.toggleTheme});

  @override
  State<TafsirSectionPage> createState() => _TafsirSectionPageState();
}

class _TafsirSectionPageState extends State<TafsirSectionPage> {
  @override
  void initState() {
    super.initState();
    // Load subcategories when page opens
    Future.microtask(() {
      Provider.of<SubcategoryProvider>(context, listen: false)
          .loadSubcategoriesBySection('التفسير');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFE4E5D3),
      appBar: AppBar(
        title: const Text('قسم التفسير'),
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
              Provider.of<SubcategoryProvider>(context, listen: false)
                  .loadSubcategoriesBySection('التفسير');
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
      drawer: widget.toggleTheme != null ? AppDrawer(toggleTheme: widget.toggleTheme!) : null,
      body: Consumer<SubcategoryProvider>(
        builder: (context, subcategoryProvider, child) {
          if (subcategoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final subcategories = subcategoryProvider.getSubcategoriesBySection('التفسير');

          if (subcategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فئات فرعية في قسم التفسير',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 30,
                      child: Icon(
                        _getIconForSubcategory(subcategory['icon_name']),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      subcategory['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: subcategory['description'] != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              subcategory['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubcategorySheikhsPage(
                            subcategoryId: subcategory['id'],
                            subcategoryName: subcategory['name'],
                            section: 'التفسير',
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
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'الإشعارات'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
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
