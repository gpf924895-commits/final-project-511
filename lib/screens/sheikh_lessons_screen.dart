import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/offline/firestore_shims.dart';
import 'package:new_project/repository/local_repository.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import '../provider/chapter_provider.dart';
import 'sheikh_lesson_form_screen.dart';

class SheikhLessonsScreen extends StatefulWidget {
  final String? selectedChapterId;

  const SheikhLessonsScreen({super.key, this.selectedChapterId});

  @override
  State<SheikhLessonsScreen> createState() => _SheikhLessonsScreenState();
}

class _SheikhLessonsScreenState extends State<SheikhLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String? _selectedChapterId;
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    _selectedChapterId = widget.selectedChapterId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
      setState(() {
        _chapters = chapterProvider.chapters;
      });
    }
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
            title: const Text('إدارة الدروس'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SheikhLessonFormScreen(),
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
                // Filters Row
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'البحث في الدروس...',
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
                      const SizedBox(height: 12),
                      // Chapter Filter
                      Row(
                        children: [
                          const Text('الفصل: '),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedChapterId,
                              hint: const Text('الكل'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('الكل'),
                                ),
                                ..._chapters.map((chapter) {
                                  return DropdownMenuItem(
                                    value: chapter['id'],
                                    child: Text(chapter['title']),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedChapterId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status Filter
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['all', 'published', 'draft'].map((
                                  filter,
                                ) {
                                  final isSelected = _selectedFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(_getFilterLabel(filter)),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      selectedColor: Colors.green[100],
                                      checkmarkColor: Colors.green,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lessons List
                Expanded(child: _buildLessonsList(categoryId, currentUid)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'الكل';
      case 'published':
        return 'المنشور';
      case 'draft':
        return 'المسودات';
      default:
        return 'الكل';
    }
  }

  Widget _buildLessonsList(String categoryId, String currentUid) {
    // For offline mode: Use LocalRepository with polling
    final repository = LocalRepository();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Stream.periodic(const Duration(seconds: 2), (_) async {
        final lectures = await repository.getLecturesBySheikh(currentUid);
        // Filter by categoryId, chapterId, and status
        return lectures.where((lecture) {
          final matchesCategory = lecture['categoryId'] == categoryId;
          final matchesChapter =
              _selectedChapterId == null ||
              lecture['chapterId'] == _selectedChapterId;
          final matchesFilter =
              _selectedFilter == 'all' || lecture['status'] == _selectedFilter;
          return matchesCategory && matchesChapter && matchesFilter;
        }).toList()..sort((a, b) {
          final aTime = a['updatedAt'] as int? ?? 0;
          final bTime = b['updatedAt'] as int? ?? 0;
          return bTime.compareTo(aTime);
        });
      }).asyncMap((future) => future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الدروس: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد دروس',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SheikhLessonFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة درس جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final lessonId = lesson['id'] as String? ?? '';
              return _buildLessonCard(lessonId, lesson);
            },
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(String lessonId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          data['title'] ?? 'بدون عنوان',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['abstract'] != null && data['abstract'].isNotEmpty)
              Text(
                data['abstract'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(data['status']),
                const SizedBox(width: 8),
                Text(
                  _formatDate(data['updatedAt']),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                  builder: (context) => SheikhLessonFormScreen(
                    lessonId: lessonId,
                    lessonData: data,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(lessonId, data['title']);
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
          // Show lesson details or play media
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('عرض تفاصيل: ${data['title']}')),
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(String lessonId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هل تريد الحذف؟'),
        content: Text('سيتم حذف هذا الدرس.\n\nالدرس: $title'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteLesson(lessonId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(String lessonId) async {
    try {
      final repository = LocalRepository();
      await repository.deleteLecture(lessonId);

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
        ).showSnackBar(SnackBar(content: Text('خطأ في حذف الدرس: $e')));
      }
    }
  }
}
