import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/offline/firestore_shims.dart';
import 'package:new_project/repository/local_repository.dart';
import 'package:new_project/database/firebase_service.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import 'sheikh_upload_screen.dart';

class SheikhLecturesScreen extends StatefulWidget {
  const SheikhLecturesScreen({super.key});

  @override
  State<SheikhLecturesScreen> createState() => _SheikhLecturesScreenState();
}

class _SheikhLecturesScreenState extends State<SheikhLecturesScreen> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'published', 'draft'];

  @override
  Widget build(BuildContext context) {
    return Consumer2<SheikhProvider, AuthProvider>(
      builder: (context, sheikhProvider, authProvider, child) {
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('جميع الدروس')),
                  const PopupMenuItem(
                    value: 'published',
                    child: Text('المنشورة'),
                  ),
                  const PopupMenuItem(value: 'draft', child: Text('المسودات')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.filter_list),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'تصفية: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filterOptions.map((filter) {
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
              ),
              const Divider(height: 1),
              // Lectures List
              Expanded(child: _buildLecturesList(categoryId, currentUid)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SheikhUploadScreen(),
                ),
              );
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildLecturesList(String categoryId, String currentUid) {
    // For offline mode: Use LocalRepository with polling
    final repository = LocalRepository();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Stream.periodic(const Duration(seconds: 2), (_) async {
        final lectures = await repository.getLecturesBySheikh(currentUid);
        // Filter by categoryId and status
        return lectures.where((lecture) {
          final matchesCategory = lecture['categoryId'] == categoryId;
          final matchesFilter =
              _selectedFilter == 'all' || lecture['status'] == _selectedFilter;
          return matchesCategory && matchesFilter;
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

        final lectures = snapshot.data ?? [];

        if (lectures.isEmpty) {
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
                  _selectedFilter == 'all'
                      ? 'لا توجد دروس بعد'
                      : 'لا توجد دروس ${_getFilterLabel(_selectedFilter)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SheikhUploadScreen(),
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
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              final lectureId = lecture['id'] as String? ?? '';
              return _buildLectureCard(lectureId, lecture);
            },
          ),
        );
      },
    );
  }

  Widget _buildLectureCard(String lectureId, Map<String, dynamic> data) {
    final sheikhProvider = Provider.of<SheikhProvider>(context, listen: false);
    final canEdit = sheikhProvider.ensureOwnership(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SheikhUploadScreen(
                          lectureId: lectureId,
                          lectureData: data,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(lectureId, data['title']);
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
              )
            : null,
        onTap: () {
          // Show lecture details or play media
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

  void _showDeleteDialog(String lectureId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الدرس "$title"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteLecture(lectureId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLecture(String lectureId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUid = authProvider.currentUid;
      if (currentUid == null) return;

      final firebaseService = FirebaseService();
      await firebaseService.deleteSheikhLecture(
        lectureId: lectureId,
        sheikhId: currentUid,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الدرس بنجاح')));
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
