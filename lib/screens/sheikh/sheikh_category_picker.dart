import 'package:flutter/material.dart';
import 'package:new_project/screens/sheikh/add_lecture_form.dart';
import 'package:new_project/widgets/sheikh_guard.dart';

class SheikhCategoryPicker extends StatelessWidget {
  const SheikhCategoryPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SheikhGuard(
      routeName: '/sheikh/add/pickCategory',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFE4E5D3),
          appBar: AppBar(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            title: const Text('اختيار فئة المحاضرة'),
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: Colors.green, size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر فئة المحاضرة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'اختر الفئة المناسبة لمحاضرتك الجديدة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Buttons
                Expanded(
                  child: Column(
                    children: [
                      _buildCategoryButton(
                        context,
                        'الفقه',
                        Icons.mosque,
                        const Color(0xFF2E7D32),
                        'fiqh',
                        'أحكام الشريعة الإسلامية',
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryButton(
                        context,
                        'السيرة',
                        Icons.person,
                        const Color(0xFF1976D2),
                        'seerah',
                        'سيرة النبي صلى الله عليه وسلم',
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryButton(
                        context,
                        'التفسير',
                        Icons.menu_book,
                        const Color(0xFF7B1FA2),
                        'tafsir',
                        'تفسير القرآن الكريم',
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryButton(
                        context,
                        'الحديث',
                        Icons.chat,
                        const Color(0xFFD32F2F),
                        'hadith',
                        'أحاديث النبي صلى الله عليه وسلم',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String categoryKey,
    String description,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddLectureForm(categoryKey: categoryKey, categoryNameAr: title),
          ),
        );
      },
      icon: Icon(icon, size: 24),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
