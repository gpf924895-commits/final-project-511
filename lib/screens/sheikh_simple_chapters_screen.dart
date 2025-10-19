import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import '../provider/chapter_provider.dart';

class SheikhSimpleChaptersScreen extends StatefulWidget {
  const SheikhSimpleChaptersScreen({super.key});

  @override
  State<SheikhSimpleChaptersScreen> createState() =>
      _SheikhSimpleChaptersScreenState();
}

class _SheikhSimpleChaptersScreenState
    extends State<SheikhSimpleChaptersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final sheikhProvider = Provider.of<SheikhProvider>(context, listen: false);
    final chapterProvider = Provider.of<ChapterProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (sheikhProvider.currentSheikhCategoryId != null &&
        authProvider.currentUser != null) {
      await chapterProvider.loadChapters(
        sheikhProvider.currentSheikhCategoryId ?? '',
        authProvider.currentUid ?? '',
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredChapters(
    List<Map<String, dynamic>> chapters,
  ) {
    if (_searchQuery.isEmpty) return chapters;
    return chapters
        .where(
          (chapter) =>
              (chapter['title'] as String?)?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  void _showAddChapterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: _AddChapterForm(
                onSave: () {
                  Navigator.pop(context);
                  _loadChapters();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditChapterBottomSheet(Map<String, dynamic> chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: _AddChapterForm(
                chapter: chapter,
                onSave: () {
                  Navigator.pop(context);
                  _loadChapters();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
            'سيتم حذف هذا الباب وجميع الدروس التابعة له. هل أنت متأكد؟',
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
      ),
    );
  }

  Future<void> _deleteChapter(Map<String, dynamic> chapter) async {
    try {
      final chapterProvider = Provider.of<ChapterProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sheikhProvider = Provider.of<SheikhProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser != null &&
          sheikhProvider.currentSheikhCategoryId != null) {
        await chapterProvider.deleteChapter(
          chapter['id'],
          sheikhProvider.currentSheikhCategoryId ?? '',
          authProvider.currentUid ?? '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم الحذف'),
              action: SnackBarAction(
                label: 'تراجع',
                onPressed: () {
                  // TODO: Implement undo logic
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SheikhProvider, AuthProvider, ChapterProvider>(
      builder: (context, sheikhProvider, authProvider, chapterProvider, child) {
        final filteredChapters = _getFilteredChapters(chapterProvider.chapters);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('البرامج/الأبواب'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'البحث في الأبواب...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  // Chapters list
                  Expanded(
                    child: filteredChapters.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد أبواب',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredChapters.length,
                            itemBuilder: (context, index) {
                              final chapter = filteredChapters[index];
                              return Dismissible(
                                key: Key(chapter['id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  color: Colors.red,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  _showDeleteConfirmation(chapter);
                                  return false; // Don't auto-dismiss
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      chapter['title'] ?? 'بدون عنوان',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(
                                            '${chapter['lessonsCount'] ?? 0}',
                                          ),
                                          backgroundColor:
                                              Colors.green.shade100,
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          chapter['status'] == 'published'
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color:
                                              chapter['status'] == 'published'
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                    onTap: () =>
                                        _showEditChapterBottomSheet(chapter),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddChapterBottomSheet,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class _AddChapterForm extends StatefulWidget {
  final Map<String, dynamic>? chapter;
  final VoidCallback onSave;

  const _AddChapterForm({this.chapter, required this.onSave});

  @override
  State<_AddChapterForm> createState() => _AddChapterFormState();
}

class _AddChapterFormState extends State<_AddChapterForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  String _status = 'draft';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.chapter != null) {
      _titleController.text = widget.chapter?['title'] ?? '';
      _detailsController.text = widget.chapter?['details'] ?? '';
      _status = widget.chapter?['status'] ?? 'draft';
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

    setState(() => _isLoading = true);

    try {
      final chapterProvider = Provider.of<ChapterProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sheikhProvider = Provider.of<SheikhProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser != null &&
          sheikhProvider.currentSheikhCategoryId != null) {
        final chapterData = {
          'title': _titleController.text,
          'details': _detailsController.text,
          'status': _status,
        };

        if (widget.chapter == null) {
          await chapterProvider.addChapter(
            title: chapterData['title']!,
            categoryId: sheikhProvider.currentSheikhCategoryId ?? '',
            sheikhUid: authProvider.currentUid ?? '',
            details: chapterData['details'],
            status: chapterData['status']!,
          );
        } else {
          await chapterProvider.updateChapter(
            chapterId: widget.chapter?['id'] ?? '',
            title: chapterData['title']!,
            details: chapterData['details'],
            status: chapterData['status']!,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
          widget.onSave();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chapter == null ? 'إضافة باب جديد' : 'تعديل الباب',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الباب *',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال عنوان الباب';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _detailsController,
            decoration: const InputDecoration(
              labelText: 'تفاصيل (اختياري)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'الحالة',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('مسودة')),
              DropdownMenuItem(value: 'published', child: Text('منشور')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'draft'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChapter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.chapter == null ? 'حفظ' : 'تحديث'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
