import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/lesson_service.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/widgets/sheikh_add_action_picker.dart';
import 'package:new_project/widgets/sheikh_chapter_form.dart';
import 'package:new_project/widgets/sheikh_lesson_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhDashboardPage extends StatefulWidget {
  const SheikhDashboardPage({super.key});

  @override
  State<SheikhDashboardPage> createState() => _SheikhDashboardPageState();
}

class _SheikhDashboardPageState extends State<SheikhDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LessonService _lessonService = LessonService();
  final SubcategoryService _subcategoryService = SubcategoryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, int>? _stats;
  List<Map<String, dynamic>> _assignedSubcategories = [];
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = false;
  String? _selectedSubcatId;
  String? _selectedChapterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;

    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _lessonService.getLessonStats(sheikhUid);
      final allowedCategories = authProvider.getAllowedCategories();
      final subcats = await _subcategoryService.listAllowedSubcategories(
        sheikhUid,
        allowedCategories,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _assignedSubcategories = subcats;
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

  Future<void> _loadChapters(String subcatId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final chapters = await _subcategoryService.listChapters(
        subcatId,
        sheikhUid,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _selectedSubcatId = subcatId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الأبواب: $e')));
      }
    }
  }

  Future<void> _loadLessons(String subcatId, String chapterId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final lessons = await _lessonService.listLessons(
        subcatId: subcatId,
        sheikhUid: sheikhUid,
        chapterId: chapterId,
      );
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _selectedChapterId = chapterId;
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

  void _showAddActionPicker() {
    if (_assignedSubcategories.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه'),
          content: const Text('لم يتم تعيين أقسام لك بعد. راجع المشرف.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SheikhAddActionPicker(
        onAddChapter: () => _navigateToAddChapter(),
        onAddLesson: () => _navigateToAddLesson(),
      ),
    );
  }

  Future<void> _navigateToAddChapter({Map<String, dynamic>? existing}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhName = authProvider.currentUser?['name'] ?? 'شيخ';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SheikhChapterForm(
          assignedSubcategories: _assignedSubcategories,
          sheikhName: sheikhName,
          existingChapter: existing,
          preselectedSubcatId: _selectedSubcatId,
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
      if (existingId == null) {
        await _firestore
            .collection('subcategories')
            .doc(data['subcatId'])
            .collection('sheikhs')
            .doc(sheikhUid)
            .collection('chapters')
            .add({
              'title': data['title'],
              'sheikhName': data['sheikhName'],
              'scheduledAt': data['scheduledAt'],
              'details': data['details'],
              'status': data['status'],
              'order': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': sheikhUid,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await _firestore
            .collection('subcategories')
            .doc(data['subcatId'])
            .collection('sheikhs')
            .doc(sheikhUid)
            .collection('chapters')
            .doc(existingId)
            .update({
              'title': data['title'],
              'scheduledAt': data['scheduledAt'],
              'details': data['details'],
              'status': data['status'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الباب')));

        if (_selectedSubcatId != null) {
          _loadChapters(_selectedSubcatId ?? '');
        }
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

  Future<void> _navigateToAddLesson({Map<String, dynamic>? existing}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhName = authProvider.currentUser?['name'] ?? 'شيخ';
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SheikhLessonForm(
          assignedSubcategories: _assignedSubcategories,
          sheikhName: sheikhName,
          sheikhUid: sheikhUid,
          existingLesson: existing,
          preselectedSubcatId: _selectedSubcatId,
          preselectedChapterId: _selectedChapterId,
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
      if (existingId == null) {
        await _firestore
            .collection('subcategories')
            .doc(data['subcatId'])
            .collection('sheikhs')
            .doc(sheikhUid)
            .collection('chapters')
            .doc(data['chapterId'])
            .collection('lessons')
            .add({
              'title': data['title'],
              'sheikhName': data['sheikhName'],
              'abstract': data['abstract'],
              'tags': data['tags'],
              'scheduledAt': data['scheduledAt'],
              'recordedAt': data['recordedAt'],
              'publishAt': data['publishAt'],
              'publishedAt': data['publishedAt'],
              'status': data['status'],
              'mediaUrl': data['mediaUrl'],
              'mediaType': data['mediaType'],
              'mediaSize': data['mediaSize'],
              'order': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': sheikhUid,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await _firestore
            .collection('subcategories')
            .doc(data['subcatId'])
            .collection('sheikhs')
            .doc(sheikhUid)
            .collection('chapters')
            .doc(data['chapterId'])
            .collection('lessons')
            .doc(existingId)
            .update({
              'title': data['title'],
              'abstract': data['abstract'],
              'tags': data['tags'],
              'scheduledAt': data['scheduledAt'],
              'recordedAt': data['recordedAt'],
              'publishAt': data['publishAt'],
              'publishedAt': data['publishedAt'],
              'status': data['status'],
              'mediaUrl': data['mediaUrl'],
              'mediaType': data['mediaType'],
              'mediaSize': data['mediaSize'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الدرس')));

        if (_selectedSubcatId != null && _selectedChapterId != null) {
          _loadLessons(_selectedSubcatId ?? '', _selectedChapterId ?? '');
        }
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

  Future<void> _deleteChapter(String chapterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الباب وجميع دروسه؟'),
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
    if (sheikhUid == null || _selectedSubcatId == null) return;

    try {
      await _subcategoryService.deleteChapter(
        _selectedSubcatId ?? '',
        sheikhUid,
        chapterId,
        sheikhUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الباب بنجاح')));
        _loadChapters(_selectedSubcatId ?? '');
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

  Future<void> _deleteLesson(String lessonId) async {
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
    if (sheikhUid == null ||
        _selectedSubcatId == null ||
        _selectedChapterId == null)
      return;

    try {
      await _lessonService.deleteLesson(
        subcatId: _selectedSubcatId ?? '',
        sheikhUid: sheikhUid,
        chapterId: _selectedChapterId ?? '',
        lessonId: lessonId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الدرس بنجاح')));
        _loadLessons(_selectedSubcatId ?? '', _selectedChapterId ?? '');
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

  Widget _buildDashboard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final sheikh = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sheikh?['name'] ?? 'شيخ',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'المعرف: ${sheikh?['sheikhId'] ?? 'غير متوفر'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_stats != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'إجمالي الدروس',
                  (_stats?['total'] ?? 0).toString(),
                  Icons.library_books,
                  Colors.blue,
                ),
                _buildStatCard(
                  'الدروس المنشورة',
                  (_stats?['published'] ?? 0).toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'الدروس كمسودات',
                  (_stats?['drafts'] ?? 0).toString(),
                  Icons.edit_note,
                  Colors.orange,
                ),
                _buildStatCard(
                  'دروس هذا الأسبوع',
                  (_stats?['thisWeek'] ?? 0).toString(),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaptersTab() {
    return Column(
      children: [
        if (_assignedSubcategories.isEmpty)
          const Expanded(
            child: Center(child: Text('لم يتم تعيين أقسام لك بعد')),
          )
        else ...[
          if (_selectedSubcatId == null)
            Expanded(
              child: ListView.builder(
                itemCount: _assignedSubcategories.length,
                itemBuilder: (context, index) {
                  final subcat = _assignedSubcategories[index];
                  return ListTile(
                    title: Text(subcat['name'] ?? 'بدون اسم'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _loadChapters(subcat['id']),
                  );
                },
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedSubcatId = null;
                        _chapters = [];
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'أبوابي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chapters.isEmpty
                  ? const Center(child: Text('لا توجد أبواب'))
                  : ListView.builder(
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        return ListTile(
                          title: Text(chapter['title'] ?? 'بدون عنوان'),
                          subtitle: chapter['status'] == 'published'
                              ? const Text('منشور')
                              : const Text('مسودة'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _navigateToAddChapter(
                                  existing: {
                                    ...chapter,
                                    'subcatId': _selectedSubcatId,
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteChapter(chapter['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLessonsTab() {
    return Column(
      children: [
        if (_selectedSubcatId == null)
          const Expanded(child: Center(child: Text('اختر قسمًا وبابًا أولاً')))
        else if (_selectedChapterId == null)
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'اختر بابًا',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      return ListTile(
                        title: Text(chapter['title'] ?? 'بدون عنوان'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _loadLessons(
                          _selectedSubcatId ?? '',
                          chapter['id'],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedChapterId = null;
                      _lessons = [];
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'دروسي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lessons.isEmpty
                ? const Center(child: Text('لا توجد دروس'))
                : ListView.builder(
                    itemCount: _lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = _lessons[index];
                      return ListTile(
                        title: Text(lesson['title'] ?? 'بدون عنوان'),
                        subtitle: Text(
                          lesson['status'] == 'published' ? 'منشور' : 'مسودة',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _navigateToAddLesson(
                                existing: {
                                  ...lesson,
                                  'subcatId': _selectedSubcatId,
                                  'chapterId': _selectedChapterId,
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLesson(lesson['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الشيخ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'لوحة التحكم'),
            Tab(text: 'الأبواب'),
            Tab(text: 'الدروس'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تأكيد تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/guest',
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('تسجيل خروج'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDashboard(), _buildChaptersTab(), _buildLessonsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActionPicker,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
    );
  }
}
