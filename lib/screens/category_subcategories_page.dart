import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/hierarchy_provider.dart';
import 'package:new_project/screens/lectures_list_page.dart';
import '../widgets/app_drawer.dart';

class CategorySubcategoriesPage extends StatefulWidget {
  final String section;
  final String sectionNameAr;
  final String categoryId;
  final String categoryName;
  final bool isDarkMode;
  final Function(bool)? toggleTheme;

  const CategorySubcategoriesPage({
    super.key,
    required this.section,
    required this.sectionNameAr,
    required this.categoryId,
    required this.categoryName,
    required this.isDarkMode,
    this.toggleTheme,
  });

  @override
  State<CategorySubcategoriesPage> createState() =>
      _CategorySubcategoriesPageState();
}

class _CategorySubcategoriesPageState extends State<CategorySubcategoriesPage> {
  @override
  void initState() {
    super.initState();
    // Load subcategories when page opens
    Future.microtask(() {
      Provider.of<HierarchyProvider>(
        context,
        listen: false,
      ).loadSubcategoriesByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFE4E5D3),
      appBar: AppBar(
        title: Text(widget.categoryName),
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
              ).loadSubcategoriesByCategory(widget.categoryId);
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
      body: Consumer<HierarchyProvider>(
        builder: (context, hierarchyProvider, child) {
          if (hierarchyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hierarchyProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    hierarchyProvider.errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<HierarchyProvider>(
                        context,
                        listen: false,
                      ).loadSubcategoriesByCategory(widget.categoryId);
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final subcategories = hierarchyProvider.subcategories;

          if (subcategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فئات فرعية في هذه الفئة',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم عرض الفئات الفرعية هنا عند إضافتها',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LecturesListPage(
                            section: widget.section,
                            sectionNameAr: widget.sectionNameAr,
                            categoryId: widget.categoryId,
                            categoryName: widget.categoryName,
                            isDarkMode: widget.isDarkMode,
                            toggleTheme: widget.toggleTheme,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('عرض المحاضرات مباشرة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
                  color: widget.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 30,
                      child: const Icon(
                        Icons.subdirectory_arrow_right,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      subcategory['name'] ?? 'بدون اسم',
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
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LecturesListPage(
                            section: widget.section,
                            sectionNameAr: widget.sectionNameAr,
                            categoryId: widget.categoryId,
                            categoryName: widget.categoryName,
                            subcategoryId: subcategory['id'],
                            subcategoryName: subcategory['name'],
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
}
