import 'package:flutter/material.dart';

class DeleteLecturePage extends StatefulWidget {
  final String section;
  const DeleteLecturePage({super.key, required this.section});

  @override
  State<DeleteLecturePage> createState() => _DeleteLecturePageState();
}

class _DeleteLecturePageState extends State<DeleteLecturePage> {
  List<String> lectures = [
    'محاضرة 1',
    'محاضرة 2',
    'محاضرة 3'
  ];

  void _confirmDelete(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "$title"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                lectures.remove(title);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ تم حذف "$title"')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حذف المحاضرات - ${widget.section}'),
        backgroundColor: Colors.red,
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
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(title),
              ),
            ),
          );
        },
      ),
    );
  }
}
