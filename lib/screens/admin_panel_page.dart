import 'package:flutter/material.dart';
import 'select_section_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  void _addLecture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectSectionPage(action: 'add')),
    );
  }

  void _editLecture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectSectionPage(action: 'edit')),
    );
  }

  void _deleteLecture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectSectionPage(action: 'delete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة محاضرة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _addLecture(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('تعديل محاضرة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => _editLecture(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('حذف محاضرة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _deleteLecture(context),
            ),
          ],
        ),
      ),
    );
  }
}
