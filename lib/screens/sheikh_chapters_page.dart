import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/utils/auth_guard.dart';
import '../widgets/app_drawer.dart';
import 'chapter_lessons_page.dart';

class SheikhChaptersPage extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;
  final String sheikhUid;
  final String sheikhName;
  final String section;
  final bool isDarkMode;
  final Function(bool)? toggleTheme;

  const SheikhChaptersPage({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.sheikhUid,
    required this.sheikhName,
    required this.section,
    required this.isDarkMode,
    this.toggleTheme,
  });

  @override
  State<SheikhChaptersPage> createState() => _SheikhChaptersPageState();
}

class _SheikhChaptersPageState extends State<SheikhChaptersPage> {
  final SubcategoryService _service = SubcategoryService();
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadChapters());
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chapters = await _service.listChapters(
        widget.subcategoryId,
        widget.sheikhUid,
      );
      setState(() {
        _chapters = chapters;
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

  Future<void> _addChapter() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check authentication
    final authenticated = await AuthGuard.requireAuth(
      context,
      onLoginSuccess: () => _addChapter(),
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

    // Show add chapter dialog
    final titleController = TextEditingController();
    final orderController = TextEditingController(
      text: (_chapters.length + 1).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة باب جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الباب',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
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
          content: Text('يرجى إدخال عنوان الباب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _service.createChapter(
        widget.subcategoryId,
        widget.sheikhUid,
        authProvider.currentUid!,
        {
          'title': titleController.text.trim(),
          'order': int.tryParse(orderController.text) ?? 0,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الباب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadChapters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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
          title: const Text('أبواب الشيخ'),
          centerTitle: true,
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChapters,
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
                      onPressed: _loadChapters,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : _chapters.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد أبواب بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addChapter,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة باب'),
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
                      'أبواب ${widget.sheikhName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
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
                                  '${chapter['order'] ?? index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                chapter['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.green,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChapterLessonsPage(
                                      subcategoryId: widget.subcategoryId,
                                      subcategoryName: widget.subcategoryName,
                                      sheikhUid: widget.sheikhUid,
                                      sheikhName: widget.sheikhName,
                                      chapterId: chapter['id'],
                                      chapterTitle: chapter['title'] ?? 'باب',
                                      section: widget.section,
                                      isDarkMode: widget.isDarkMode,
                                      toggleTheme: widget.toggleTheme,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: canEdit && _chapters.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _addChapter,
                icon: const Icon(Icons.add),
                label: const Text('إضافة باب'),
                backgroundColor: Colors.green,
              )
            : null,
      ),
    );
  }
}
