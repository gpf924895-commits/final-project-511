import 'package:flutter/material.dart';
import 'add_lecture_page.dart';
import 'edit_lecture_page.dart';
import 'delete_lecture_page.dart';
import '../utils/page_transition.dart';

class SelectSectionPage extends StatelessWidget {
  final String action;
  const SelectSectionPage({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final List<String> sections = [
      'قسم الحديث',
      'قسم الفقه',
      'قسم التفسير',
      'قسم السيرة',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('اختيار القسم - ${_getTitle(action)}'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(sections[index]),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (action == 'add') {
                  SmoothPageTransition.navigateTo(
                    context,
                    AddLecturePage(section: sections[index]),
                  );
                } else if (action == 'edit') {
                  SmoothPageTransition.navigateTo(
                    context,
                    EditLecturePage(section: sections[index]),
                  );
                } else if (action == 'delete') {
                  SmoothPageTransition.navigateTo(
                    context,
                    DeleteLecturePage(section: sections[index]),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذه الصفحة لم تُبرمج بعد')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  String _getTitle(String act) {
    switch (act) {
      case 'add':
        return 'إضافة';
      case 'edit':
        return 'تعديل';
      case 'delete':
        return 'حذف';
      default:
        return '';
    }
  }
}
