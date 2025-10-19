import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import '../provider/chapter_provider.dart';

class SheikhChapterFormScreen extends StatefulWidget {
  final String? chapterId;
  final Map<String, dynamic>? chapterData;

  const SheikhChapterFormScreen({super.key, this.chapterId, this.chapterData});

  @override
  State<SheikhChapterFormScreen> createState() =>
      _SheikhChapterFormScreenState();
}

class _SheikhChapterFormScreenState extends State<SheikhChapterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  String _status = 'draft';
  DateTime? _scheduledAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.chapterData != null) {
      _loadChapterData();
    }
  }

  void _loadChapterData() {
    final data = widget.chapterData ?? {};
    _titleController.text = data['title'] ?? '';
    _detailsController.text = data['details'] ?? '';
    _status = data['status'] ?? 'draft';

    if (data['scheduledAt'] != null) {
      _scheduledAt = data['scheduledAt'].toDate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _saveChapter() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sheikhProvider = Provider.of<SheikhProvider>(
        context,
        listen: false,
      );
      final chapterProvider = Provider.of<ChapterProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final categoryId = sheikhProvider.currentSheikhCategoryId;
      final currentUid = authProvider.currentUser?['uid'];

      if (categoryId == null || currentUid == null) {
        throw Exception('بيانات الشيخ غير صحيحة');
      }

      if (widget.chapterId != null) {
        // Update existing chapter
        final success = await chapterProvider.updateChapter(
          chapterId: widget.chapterId ?? '',
          title: _titleController.text.trim(),
          details: _detailsController.text.trim(),
          scheduledAt: _scheduledAt,
          status: _status,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تم حفظ الباب')));
            Navigator.pop(context);
          }
        }
      } else {
        // Create new chapter
        final chapterId = await chapterProvider.addChapter(
          title: _titleController.text.trim(),
          categoryId: categoryId,
          sheikhUid: currentUid,
          details: _detailsController.text.trim(),
          scheduledAt: _scheduledAt,
          status: _status,
        );

        if (chapterId != null) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تم حفظ الباب')));
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حفظ الباب: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chapterId != null ? 'تحرير الباب' : 'إضافة باب جديد',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChapter,
            child: Text(
              'حفظ',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Field (readonly)
                Consumer<SheikhProvider>(
                  builder: (context, sheikhProvider, child) {
                    return TextFormField(
                      initialValue: 'القسم محدد تلقائياً',
                      decoration: const InputDecoration(
                        labelText: 'القسم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      readOnly: true,
                      style: TextStyle(color: Colors.grey[600]),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الباب *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'عنوان الباب مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Details Field
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Status Field
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.visibility),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                    DropdownMenuItem(value: 'published', child: Text('منشور')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value ?? 'draft';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Scheduled Date Field
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التواريخ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.schedule),
                          title: const Text('تاريخ مجدول'),
                          subtitle: Text(
                            _scheduledAt != null
                                ? '${_scheduledAt?.day ?? 0}/${_scheduledAt?.month ?? 0}/${_scheduledAt?.year ?? 0}'
                                : 'لم يتم تحديده',
                          ),
                          trailing: IconButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _scheduledAt ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  _scheduledAt = date;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChapter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.chapterId != null
                                ? 'تحديث الباب'
                                : 'إضافة الباب',
                            style: const TextStyle(fontSize: 16),
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
