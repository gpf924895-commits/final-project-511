import 'package:flutter/material.dart';

class EditLecturePage extends StatefulWidget {
  final String section;
  const EditLecturePage({super.key, required this.section});

  @override
  State<EditLecturePage> createState() => _EditLecturePageState();
}

class _EditLecturePageState extends State<EditLecturePage> {
  final List<String> lectures = [
    'محاضرة 1',
    'محاضرة 2',
    'محاضرة 3'
  ];

  void _openEditDialog(String oldTitle) {
    final TextEditingController _controller = TextEditingController(text: oldTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المحاضرة'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'عنوان المحاضرة الجديد'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم تعديل المحاضرة إلى "${_controller.text}"')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل المحاضرات - ${widget.section}'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: ListView.builder(
        itemCount: lectures.length,
        itemBuilder: (context, index) {
          final title = lectures[index];
          return Card(
            child: ListTile(
              title: Text(title),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _openEditDialog(title),
              ),
            ),
          );
        },
      ),
    );
  }
}
