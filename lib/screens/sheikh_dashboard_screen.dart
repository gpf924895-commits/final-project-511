import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/repository/local_repository.dart';
import '../provider/sheikh_provider.dart';
import '../provider/pro_login.dart';
import 'sheikh_simple_chapters_screen.dart';
import 'sheikh_simple_lessons_screen.dart';
import '../services/sheikh_nav_guard.dart';

class SheikhDashboardScreen extends StatefulWidget {
  const SheikhDashboardScreen({super.key});

  @override
  State<SheikhDashboardScreen> createState() => _SheikhDashboardScreenState();
}

class _SheikhDashboardScreenState extends State<SheikhDashboardScreen> {
  Map<String, int> _kpis = {
    'total': 0,
    'published': 0,
    'draft': 0,
    'thisWeek': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadKPIs();
  }

  Future<void> _loadKPIs() async {
    final sheikhProvider = Provider.of<SheikhProvider>(context, listen: false);
    final categoryId = sheikhProvider.currentSheikhCategoryId;
    final currentUid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?['uid'];

    if (categoryId == null || currentUid == null) return;

    try {
      // For offline mode: Get stats from LocalRepository
      final repository = LocalRepository();
      final lectures = await repository.getLecturesBySheikh(currentUid);

      // Filter by categoryId
      final categoryLectures = lectures
          .where((lecture) => lecture['categoryId'] == categoryId)
          .toList();

      // Get this week's lessons
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - now.weekday + 1,
      ).millisecondsSinceEpoch;

      setState(() {
        _kpis = {
          'total': categoryLectures.length,
          'published': categoryLectures
              .where((l) => l['status'] == 'published')
              .length,
          'draft': categoryLectures.where((l) => l['status'] == 'draft').length,
          'thisWeek': categoryLectures.where((l) {
            final createdAt = l['createdAt'] as int? ?? 0;
            return createdAt >= weekStart;
          }).length,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الإحصائيات: $e')));
    }
  }

  void _showAddContentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة محتوى جديد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.folder, color: Colors.green),
                  title: const Text('إضافة باب'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SheikhSimpleChaptersScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.green),
                  title: const Text('إضافة درس'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SheikhSimpleLessonsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SheikhProvider, AuthProvider>(
      builder: (context, sheikhProvider, authProvider, child) {
        if (sheikhProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (sheikhProvider.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('لوحة الشيخ')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    sheikhProvider.error ?? 'حدث خطأ غير متوقع',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      sheikhProvider.ensureRoleSheikh();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('لوحة الشيخ'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  (sheikhProvider.sheikhData?['name'] ?? 'ش')
                                      .substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sheikhProvider.sheikhData?['name'] ??
                                          'غير محدد',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'رقم الشيخ: ${sheikhProvider.sheikhData?['sheikhId'] ?? 'غير محدد'}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      authProvider.currentUser?['email'] ??
                                          'غير محدد',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KPI Row
                  const Text(
                    'الإحصائيات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKPICard(
                          'إجمالي الدروس',
                          _kpis['total']!,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKPICard(
                          'المنشور',
                          _kpis['published']!,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKPICard(
                          'المسودات',
                          _kpis['draft']!,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKPICard(
                          'هذا الأسبوع',
                          _kpis['thisWeek']!,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  const Text(
                    'الإجراءات السريعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'إدارة الأبواب',
                          Icons.folder,
                          () => SheikhAuthGuard.validateThenNavigate(
                            context,
                            () => Navigator.pushNamed(
                              context,
                              '/sheikh/chapters',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionCard(
                          'إدارة الدروس',
                          Icons.video_library,
                          () => SheikhAuthGuard.validateThenNavigate(
                            context,
                            () =>
                                Navigator.pushNamed(context, '/sheikh/lessons'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddContentBottomSheet,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String title, int value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
