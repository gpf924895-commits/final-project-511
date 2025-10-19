import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/lesson_service.dart';
import 'package:new_project/widgets/sheikh_add_action_picker.dart';
import 'package:new_project/services/sheikh_nav_guard.dart';

class SheikhDashboardTab extends StatefulWidget {
  const SheikhDashboardTab({super.key});

  @override
  State<SheikhDashboardTab> createState() => _SheikhDashboardTabState();
}

class _SheikhDashboardTabState extends State<SheikhDashboardTab> {
  final LessonService _lessonService = LessonService();
  Map<String, int>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadStats());
  }

  Future<void> _loadStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _lessonService.getLessonStats(sheikhUid);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الإحصائيات: $e')));
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
            _loadStats(); // Refresh stats
          }
        },
        onAddChapter: () async {
          final result = await SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/chapters'),
          );
          if (result && mounted) {
            _loadStats(); // Refresh stats
          }
        },
        onAddLesson: () async {
          final result = await SheikhAuthGuard.validateThenNavigate(
            context,
            () => Navigator.pushNamed(context, '/sheikh/upload'),
          );
          if (result && mounted) {
            _loadStats(); // Refresh stats
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sheikh = authProvider.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(sheikh),
                  const SizedBox(height: 24),
                  Text(
                    'الإحصائيات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_stats != null)
                    _buildStatsGrid(),
                  const SizedBox(height: 24),
                  Text(
                    'الإجراءات السريعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionCards(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? sheikh) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.green, Colors.green.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.person, size: 40, color: Colors.green.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheikh?['name'] ?? 'شيخ',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المعرف: ${sheikh?['sheikhId'] ?? 'غير متوفر'}',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  if (sheikh?['email'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sheikh?['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'إجمالي الدروس',
              (_stats?['total'] ?? 0).toString(),
              Icons.library_books,
              const Color(0xFF4A90E2),
            ),
            _buildStatCard(
              'المنشور',
              (_stats?['published'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF50C878),
            ),
            _buildStatCard(
              'المسودات',
              (_stats?['drafts'] ?? 0).toString(),
              Icons.edit_note,
              const Color(0xFFFF9500),
            ),
            _buildStatCard(
              'هذا الأسبوع',
              (_stats?['thisWeek'] ?? 0).toString(),
              Icons.calendar_today,
              const Color(0xFF9B59B6),
            ),
          ],
        );
      },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _buildActionCard(
          'إضافة محتوى جديد',
          'إضافة باب أو درس',
          Icons.add_circle,
          Colors.green,
          () {
            _showAddActionPicker();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'إدارة البرامج',
                'عرض وتحرير',
                Icons.folder_special,
                const Color(0xFF4A90E2),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('انتقل إلى تبويب البرامج')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'الإحصائيات',
                'تقارير تفصيلية',
                Icons.analytics,
                const Color(0xFF9B59B6),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قريبًا: تقارير تفصيلية')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
