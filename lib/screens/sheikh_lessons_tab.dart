import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/lesson_service.dart';

class SheikhLessonsTab extends StatefulWidget {
  const SheikhLessonsTab({super.key});

  @override
  State<SheikhLessonsTab> createState() => _SheikhLessonsTabState();
}

class _SheikhLessonsTabState extends State<SheikhLessonsTab> {
  final LessonService _service = LessonService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadLessons());
  }

  Future<void> _loadLessons() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      // This is a simplified approach - in production you'd want to
      // aggregate lessons across all programs more efficiently
      await _service.getLessonStats(sheikhUid);

      // For now, show a placeholder message
      // In a real implementation, you'd fetch all lessons across programs
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الدروس: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('الدروس'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'عرض جميع الدروس',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'لعرض الدروس، انتقل إلى برنامج معين من تبويب البرامج',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
