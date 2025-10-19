import 'package:flutter/material.dart';

class SheikhAddActionPicker extends StatelessWidget {
  final VoidCallback? onAddProgram;
  final VoidCallback? onAddChapter;
  final VoidCallback? onAddLesson;

  const SheikhAddActionPicker({
    super.key,
    this.onAddProgram,
    this.onAddChapter,
    this.onAddLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'ماذا تريد أن تضيف؟',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (onAddProgram != null) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.library_books, color: Colors.purple.shade700),
              ),
              title: const Text('إضافة برنامج'),
              subtitle: const Text('إنشاء برنامج جديد'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onAddProgram?.call();
              },
            ),
            const SizedBox(height: 12),
          ],
          if (onAddChapter != null) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder, color: Colors.blue.shade700),
              ),
              title: const Text('إضافة باب'),
              subtitle: const Text('إنشاء باب جديد لتنظيم الدروس'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onAddChapter?.call();
              },
            ),
            const SizedBox(height: 12),
          ],
          if (onAddLesson != null) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_lesson, color: Colors.green.shade700),
              ),
              title: const Text('إضافة درس'),
              subtitle: const Text('إضافة درس جديد مع إمكانية رفع المقطع'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onAddLesson?.call();
              },
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}
