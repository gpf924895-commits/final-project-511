import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import '../provider/chapter_provider.dart';
import 'sheikh_chapter_form_screen.dart';
import 'sheikh_lessons_screen.dart';

class SheikhChaptersScreen extends StatefulWidget {
  const SheikhChaptersScreen({super.key});

  @override
  State<SheikhChaptersScreen> createState() => _SheikhChaptersScreenState();
}

class _SheikhChaptersScreenState extends State<SheikhChaptersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    final sheikhProvider = Provider.of<SheikhProvider>(context, listen: false);
    final chapterProvider = Provider.of<ChapterProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final categoryId = sheikhProvider.currentSheikhCategoryId;
    final currentUid = authProvider.currentUser?['uid'];

    if (categoryId != null && currentUid != null) {
      await chapterProvider.loadChapters(categoryId, currentUid);
    }
  }

  List<Map<String, dynamic>> get _filteredChapters {
    final chapterProvider = Provider.of<ChapterProvider>(
      context,
      listen: false,
    );
    if (_searchQuery.isEmpty) {
      return chapterProvider.chapters;
    }
    return chapterProvider.chapters
        .where(
          (chapter) => chapter['title'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SheikhProvider, AuthProvider, ChapterProvider>(
      builder: (context, sheikhProvider, authProvider, chapterProvider, child) {
        final categoryId = sheikhProvider.currentSheikhCategoryId;
        final currentUid = authProvider.currentUser?['uid'];

        if (categoryId == null || currentUid == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة الأبواب'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SheikhChapterFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث في الأبواب...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                // Chapters List
                Expanded(child: _buildChaptersList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChaptersList() {
    return Consumer<ChapterProvider>(
      builder: (context, chapterProvider, child) {
        if (chapterProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chapterProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  chapterProvider.error ?? 'حدث خطأ غير متوقع',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadChapters,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final chapters = _filteredChapters;

        if (chapters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'لا توجد أبواب بعد'
                      : 'لا توجد نتائج للبحث',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SheikhChapterFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة باب جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadChapters,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return _buildChapterCard(chapter);
            },
          ),
        );
      },
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          chapter['title'] ?? 'بدون عنوان',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chapter['details'] != null && chapter['details'].isNotEmpty)
              Text(
                chapter['details'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(chapter['status']),
                const SizedBox(width: 8),
                FutureBuilder<int>(
                  future: _getLessonCount(chapter['id']),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count درس',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SheikhChapterFormScreen(
                    chapterId: chapter['id'],
                    chapterData: chapter,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(chapter);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('تحرير'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to lessons filtered by this chapter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SheikhLessonsScreen(selectedChapterId: chapter['id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'published':
        color = Colors.green;
        label = 'منشور';
        break;
      case 'draft':
        color = Colors.orange;
        label = 'مسودة';
        break;
      default:
        color = Colors.grey;
        label = 'غير محدد';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<int> _getLessonCount(String chapterId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('lectures')
          .where('chapterId', isEqualTo: chapterId)
          .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  void _showDeleteDialog(Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هل تريد الحذف؟'),
        content: Text(
          'سيتم حذف هذا الباب وجميع الدروس التابعة له.\n\nالباب: ${chapter['title']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChapter(chapter);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChapter(Map<String, dynamic> chapter) async {
    final chapterProvider = Provider.of<ChapterProvider>(
      context,
      listen: false,
    );
    final sheikhProvider = Provider.of<SheikhProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final categoryId = sheikhProvider.currentSheikhCategoryId;
    final currentUid = authProvider.currentUser?['uid'];

    if (categoryId == null || currentUid == null) return;

    try {
      await chapterProvider.deleteChapter(
        chapter['id'],
        categoryId,
        currentUid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم الحذف — تراجع؟'),
            action: SnackBarAction(
              label: 'تراجع',
              onPressed: () {
                // TODO: Implement undo functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم التراجع')));
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حذف الباب: $e')));
      }
    }
  }
}
