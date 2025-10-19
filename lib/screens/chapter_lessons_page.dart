import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/utils/auth_guard.dart';
import '../widgets/app_drawer.dart';

class ChapterLessonsPage extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;
  final String sheikhUid;
  final String sheikhName;
  final String chapterId;
  final String chapterTitle;
  final String section;
  final bool isDarkMode;
  final Function(bool)? toggleTheme;

  const ChapterLessonsPage({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.sheikhUid,
    required this.sheikhName,
    required this.chapterId,
    required this.chapterTitle,
    required this.section,
    required this.isDarkMode,
    this.toggleTheme,
  });

  @override
  State<ChapterLessonsPage> createState() => _ChapterLessonsPageState();
}

class _ChapterLessonsPageState extends State<ChapterLessonsPage> {
  final SubcategoryService _service = SubcategoryService();
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadLessons());
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessons = await _service.listLessons(
        widget.subcategoryId,
        widget.sheikhUid,
        widget.chapterId,
      );
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } on SubcategoryServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });

      if (e.needsIndex && e.indexUrl != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'يرجى إنشاء الفهرس المطلوب في قاعدة البيانات. راجع وحدة التحكم للحصول على الرابط.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check authentication
    final authenticated = await AuthGuard.requireAuth(
      context,
      onLoginSuccess: () => _addLesson(),
    );
    if (!authenticated) return;

    // Check if current user is the assigned sheikh
    if (authProvider.currentUid != widget.sheikhUid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ليس لديك صلاحية لإضافة محتوى في هذا الباب.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show add lesson dialog
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final mediaUrlController = TextEditingController();
    final durationController = TextEditingController();
    final orderController = TextEditingController(
      text: (_lessons.length + 1).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة درس جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الدرس',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mediaUrlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الوسائط (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'المدة بالدقائق (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عنوان الدرس'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _service.createLesson(
        widget.subcategoryId,
        widget.sheikhUid,
        widget.chapterId,
        authProvider.currentUid ?? '',
        {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'mediaUrl': mediaUrlController.text.trim().isEmpty
              ? null
              : mediaUrlController.text.trim(),
          'duration': durationController.text.trim().isEmpty
              ? null
              : int.tryParse(durationController.text),
          'order': int.tryParse(orderController.text) ?? 0,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الدرس بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadLessons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLessonDetails(Map<String, dynamic> lesson) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(lesson['title'] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lesson['description'] != null &&
                    lesson['description'].toString().isNotEmpty) ...[
                  const Text(
                    'الوصف:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(lesson['description']),
                  const SizedBox(height: 16),
                ],
                if (lesson['duration'] != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text('المدة: ${lesson['duration']} دقيقة'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (lesson['mediaUrl'] != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.video_library,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'يحتوي على وسائط',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canEdit =
        authProvider.isAuthenticated &&
        authProvider.currentUid == widget.sheikhUid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: Text(widget.chapterTitle),
          centerTitle: true,
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLessons,
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLessons,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : _lessons.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_lesson, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد دروس بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addLesson,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة درس'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دروس ${widget.chapterTitle}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
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
                                backgroundColor: Colors.green,
                                radius: 24,
                                child: Text(
                                  '${lesson['order'] ?? index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                lesson['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle:
                                  lesson['description'] != null &&
                                      lesson['description']
                                          .toString()
                                          .isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        lesson['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : null,
                              trailing: lesson['mediaUrl'] != null
                                  ? const Icon(
                                      Icons.video_library,
                                      color: Colors.green,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.green,
                                    ),
                              onTap: () => _showLessonDetails(lesson),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: canEdit && _lessons.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _addLesson,
                icon: const Icon(Icons.add),
                label: const Text('إضافة درس'),
                backgroundColor: Colors.green,
              )
            : null,
      ),
    );
  }
}
