import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'dart:developer' as developer;

class SheikhProgramsScreen extends StatefulWidget {
  const SheikhProgramsScreen({super.key});

  @override
  State<SheikhProgramsScreen> createState() => _SheikhProgramsScreenState();
}

class _SheikhProgramsScreenState extends State<SheikhProgramsScreen> {
  final SubcategoryService _subcategoryService = SubcategoryService();
  List<Map<String, dynamic>> _programs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _indexCreateUrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadPrograms());
  }

  Future<void> _loadPrograms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;

    if (sheikhUid == null) return;

    setState(() {
      _isLoading = true;
      _indexCreateUrl = null;
    });

    try {
      final allowedCategories = authProvider.getAllowedCategories();
      final programs = await _subcategoryService.listAllowedSubcategories(
        sheikhUid,
        allowedCategories,
      );

      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل البرامج: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPrograms {
    if (_searchQuery.isEmpty) return _programs;

    return _programs.where((program) {
      final name = (program['name'] ?? '').toString().toLowerCase();
      final description = (program['description'] ?? '')
          .toString()
          .toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  Widget _buildIndexErrorPanel() {
    if (_indexCreateUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'فشل تحميل القائمة بالاستعلام الكامل — يحتاج فهرس مركب.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إنشاء الفهرس في Firebase Console.',
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ رابط إنشاء الفهرس')),
                    );
                    developer.log('Firestore Index URL: $_indexCreateUrl');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ رابط إنشاء الفهرس'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadPrograms,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_outlined,
            color: Colors.green[600],
            size: 24,
          ),
        ),
        title: Text(
          program['name'] ?? 'بدون اسم',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: program['description'] != null
            ? Text(
                program['description'],
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/sheikh/program/episodes',
            arguments: program,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لم يتم تعيين برامج لك بعد',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التواصل مع المشرف لتعيين البرامج',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('البرامج'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'البحث في البرامج...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_indexCreateUrl != null) _buildIndexErrorPanel(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPrograms.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPrograms,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredPrograms.length,
                        itemBuilder: (context, index) {
                          return _buildProgramCard(_filteredPrograms[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
