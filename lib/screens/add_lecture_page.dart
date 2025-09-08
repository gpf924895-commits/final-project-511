import 'package:flutter/material.dart';

class AddLecturePage extends StatefulWidget {
  final String section;
  const AddLecturePage({super.key, required this.section});

  @override
  State<AddLecturePage> createState() => _AddLecturePageState();
}

class _AddLecturePageState extends State<AddLecturePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _saveLecture() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }

    // هنا تقدر تخزن البيانات في قاعدة بيانات مستقبلًا
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم إضافة المحاضرة إلى ${widget.section}')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة محاضرة - ${widget.section}'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان المحاضرة',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'محتوى المحاضرة',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveLecture,
              icon: const Icon(Icons.save),
              label: const Text('حفظ المحاضرة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
