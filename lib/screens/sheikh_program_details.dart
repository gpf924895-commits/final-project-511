import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/services/lesson_service.dart';
import 'package:new_project/screens/sheikh_player_screen.dart';
import 'package:new_project/widgets/sheikh_add_action_picker.dart';
import 'package:new_project/widgets/sheikh_chapter_form.dart';
import 'package:new_project/widgets/sheikh_lesson_form.dart';
import 'package:new_project/services/sheikh_nav_guard.dart';

class SheikhProgramDetails extends StatefulWidget {
  final String programId;
  final String programName;

  const SheikhProgramDetails({
    super.key,
    required this.programId,
    required this.programName,
  });

  @override
  State<SheikhProgramDetails> createState() => _SheikhProgramDetailsState();
}

class _SheikhProgramDetailsState extends State<SheikhProgramDetails> {
  final SubcategoryService _subcategoryService = SubcategoryService();
  final LessonService _lessonService = LessonService();

  List<Map<String, dynamic>> _chapters = [];
  Map<String, List<Map<String, dynamic>>> _lessonsByChapter = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final chapters = await _subcategoryService.listChapters(
        widget.programId,
        sheikhUid,
      );

      final lessonsByChapter = <String, List<Map<String, dynamic>>>{};
      for (final chapter in chapters) {
        final lessons = await _lessonService.listLessons(
          subcatId: widget.programId,
          sheikhUid: sheikhUid,
          chapterId: chapter['id'],
        );
        lessonsByChapter[chapter['id']] = lessons;
      }

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _lessonsByChapter = lessonsByChapter;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل البيانات: $e')));
      }
    }
  }

  void _showAddActionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SheikhAddActionPicker(
        onAddProgram: () async {
          final result = await SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/program'),
          );
          if (result && mounted) {
            _loadData(); // Refresh data
          }
        },
        onAddChapter: () async {
          final result = await SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/chapters'),
          );
          if (result && mounted) {
            _loadData(); // Refresh data
          }
        },
        onAddLesson: () async {
          final result = await SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/upload'),
          );
          if (result && mounted) {
            _loadData(); // Refresh data
          }
        },
      ),
    );
  }

  Future<void> _navigateToAddChapter({Map<String, dynamic>? existing}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhName = authProvider.currentUser?['name'] ?? 'شيخ';
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SheikhChapterForm(
          assignedSubcategories: [
            {'id': widget.programId, 'name': widget.programName},
          ],
          sheikhName: sheikhName,
          existingChapter: existing,
          preselectedSubcatId: widget.programId,
          onSave: (data) => _handleSaveChapter(data, existing?['id']),
        ),
      ),
    );
  }

  Future<void> _handleSaveChapter(
    Map<String, dynamic> data,
    String? existingId,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    try {
      // TODO: Implement chapter creation in LocalRepository
      // For now, use SubcategoryService which is stubbed
      await _subcategoryService.createChapter(
        widget.programId,
        sheikhUid,
        data['title'] ?? '',
        data,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الباب')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  Future<void> _navigateToAddLesson({
    Map<String, dynamic>? existing,
    String? chapterId,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhName = authProvider.currentUser?['name'] ?? 'شيخ';
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SheikhLessonForm(
          assignedSubcategories: [
            {'id': widget.programId, 'name': widget.programName},
          ],
          sheikhName: sheikhName,
          sheikhUid: sheikhUid,
          existingLesson: existing,
          preselectedSubcatId: widget.programId,
          preselectedChapterId: chapterId,
          onSave: (data) => _handleSaveLesson(data, existing?['id']),
        ),
      ),
    );
  }

  Future<void> _handleSaveLesson(
    Map<String, dynamic> data,
    String? existingId,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    try {
      // TODO: Implement lesson creation in LocalRepository
      // For now, use SubcategoryService which is stubbed
      await _subcategoryService.createLesson(
        widget.programId,
        sheikhUid,
        data['chapterId'] ?? '',
        sheikhUid,
        data,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الدرس')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل: $e')));
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
          title: Text(widget.programName),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chapters.isEmpty
            ? Center(
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
                      'لا توجد دروس بعد',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chapters.length,
                  itemBuilder: (context, chapterIndex) {
                    final chapter = _chapters[chapterIndex];
                    final lessons = _lessonsByChapter[chapter['id']] ?? [];
                    return _buildChapterSection(chapter, lessons);
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddActionPicker,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة'),
        ),
      ),
    );
  }

  Widget _buildChapterSection(
    Map<String, dynamic> chapter,
    List<Map<String, dynamic>> lessons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chapter['title'] ?? 'باب بدون عنوان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.green.shade700,
                onPressed: () => _navigateToAddChapter(
                  existing: {...chapter, 'subcatId': widget.programId},
                ),
              ),
            ],
          ),
        ),
        if (lessons.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'لا توجد دروس في هذا الباب',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...lessons.asMap().entries.map((entry) {
            final index = entry.key;
            final lesson = entry.value;
            return _buildEpisodeCard(lesson, index + 1, chapter['id']);
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEpisodeCard(
    Map<String, dynamic> lesson,
    int episodeNumber,
    String chapterId,
  ) {
    final hasMedia = lesson['mediaUrl'] != null;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          if (hasMedia) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SheikhPlayerScreen(
                  episode: {
                    'id': lesson['id'],
                    'title': lesson['title'] ?? 'درس',
                    'mediaUrl': lesson['mediaUrl'],
                    'programName': widget.programName,
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا يوجد ملف صوتي لهذا الدرس')),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasMedia ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasMedia ? Icons.play_arrow : Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$episodeNumber- ${lesson['title'] ?? 'بدون عنوان'}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson['abstract'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson['abstract'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (lesson['status'] == 'published')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'منشور',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'مسودة',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToAddLesson(
                          existing: {
                            ...lesson,
                            'subcatId': widget.programId,
                            'chapterId': chapterId,
                          },
                          chapterId: chapterId,
                        );
                      } else if (value == 'delete') {
                        _deleteLesson(lesson['id'], chapterId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLesson(String lessonId, String chapterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدرس؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    try {
      await _lessonService.deleteLesson(
        subcatId: widget.programId,
        sheikhUid: sheikhUid,
        chapterId: chapterId,
        lessonId: lessonId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الدرس بنجاح')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }
}
