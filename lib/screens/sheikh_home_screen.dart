import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/lesson_service.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/widgets/sheikh_add_action_picker.dart';
import 'package:new_project/services/sheikh_nav_guard.dart';

class SheikhHomeScreen extends StatefulWidget {
  const SheikhHomeScreen({super.key});

  @override
  State<SheikhHomeScreen> createState() => _SheikhHomeScreenState();
}

class _SheikhHomeScreenState extends State<SheikhHomeScreen> {
  final LessonService _lessonService = LessonService();
  final SubcategoryService _subcategoryService = SubcategoryService();

  Map<String, int>? _stats;
  List<Map<String, dynamic>> _assignedSubcategories = [];
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

  Widget _buildHeroCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final sheikh = authProvider.currentUser;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400] ?? Colors.green, Colors.green[600] ?? Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.green[600]),
            ),
            const SizedBox(height: 16),
            Text(
              sheikh?['name'] ?? 'شيخ',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المعرف: ${sheikh?['sheikhId'] ?? 'غير متوفر'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (sheikh?['email'] != null) ...[
              const SizedBox(height: 4),
              Text(
                sheikh?['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.green[600], size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('لوحة تحكم الشيخ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
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
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).signOut();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 24),
                      if (_stats != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'الإحصائيات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              _buildKpiCard(
                                'إجمالي الدروس',
                                (_stats?['total'] ?? 0).toString(),
                                Icons.library_books,
                                Colors.blue,
                              ),
                              _buildKpiCard(
                                'المنشور',
                                (_stats?['published'] ?? 0).toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                              _buildKpiCard(
                                'المسودات',
                                (_stats?['drafts'] ?? 0).toString(),
                                Icons.edit_note,
                                Colors.orange,
                              ),
                              _buildKpiCard(
                                'هذا الأسبوع',
                                (_stats?['thisWeek'] ?? 0).toString(),
                                Icons.calendar_today,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'الإجراءات السريعة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActionCard(
                        'إضافة محتوى جديد',
                        'إضافة برنامج أو باب أو درس',
                        Icons.add_circle_outline,
                        () => _showAddContentSheet(),
                      ),
                      _buildQuickActionCard(
                        'إدارة البرامج',
                        '${_assignedSubcategories.length} برنامج متاح',
                        Icons.folder_outlined,
                        () => SheikhAuthGuard.validateThenNavigate(
                          context,
                          () =>
                              Navigator.pushNamed(context, '/sheikh/programs'),
                        ),
                      ),
                      _buildQuickActionCard(
                        'إدارة الأبواب',
                        'تنظيم أبواب البرامج',
                        Icons.menu_book_outlined,
                        () => SheikhAuthGuard.validateThenNavigate(
                          context,
                          () =>
                              Navigator.pushNamed(context, '/sheikh/chapters'),
                        ),
                      ),
                      _buildQuickActionCard(
                        'إدارة الدروس',
                        'إدارة جميع الدروس',
                        Icons.play_lesson_outlined,
                        () => SheikhAuthGuard.validateThenNavigate(
                          context,
                          () => Navigator.pushNamed(context, '/sheikh/lessons'),
                        ),
                      ),
                      _buildQuickActionCard(
                        'الإحصائيات التفصيلية',
                        'عرض تقارير مفصلة',
                        Icons.analytics_outlined,
                        () => SheikhAuthGuard.validateThenNavigate(
                          context,
                          () =>
                              Navigator.pushNamed(context, '/sheikh/analytics'),
                        ),
                      ),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContentSheet(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
    );
  }

  void _showAddContentSheet() {
    if (_assignedSubcategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تعيين أقسام لك بعد.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheikhAddActionPicker(
        onAddProgram: () {
          Navigator.pop(ctx);
          SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/program/create'),
          );
        },
        onAddChapter: () {
          Navigator.pop(ctx);
          SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/chapter/create'),
          );
        },
        onAddLesson: () {
          Navigator.pop(ctx);
          SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/lesson/create'),
          );
        },
      ),
    );
  }
}
