import 'package:flutter/material.dart';

class HadithSectionPage extends StatelessWidget {
  final bool isDarkMode;
  const HadithSectionPage({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFE4E5D3),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('قسم الحديث'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: 4, // عدد الأقسام المؤقتة
          itemBuilder: (context, index) {
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // زر القسم
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_stories, size: 32),
                  SizedBox(height: 8),
                  Text('قسم ١'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
