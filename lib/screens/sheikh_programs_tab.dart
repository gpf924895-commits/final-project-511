import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/screens/sheikh_program_details.dart';

class SheikhProgramsTab extends StatefulWidget {
  const SheikhProgramsTab({super.key});

  @override
  State<SheikhProgramsTab> createState() => _SheikhProgramsTabState();
}

class _SheikhProgramsTabState extends State<SheikhProgramsTab> {
  final SubcategoryService _service = SubcategoryService();
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _filteredPrograms = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadPrograms());
    _searchController.addListener(_filterPrograms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    setState(() => _isLoading = true);

    try {
      final programs = await _service.listAssignedSubcategories(sheikhUid);
      if (mounted) {
        setState(() {
          _programs = programs;
          _filteredPrograms = programs;
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

  void _filterPrograms() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPrograms = _programs;
      } else {
        _filteredPrograms = _programs
            .where(
              (p) => (p['name'] ?? '').toString().toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('البرامج'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFE4E5D3),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث في البرامج...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPrograms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _programs.isEmpty
                                  ? 'لم يتم تعيين برامج لك بعد'
                                  : 'لا توجد نتائج',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPrograms,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPrograms.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final program = _filteredPrograms[index];
                            return _buildProgramCard(program);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SheikhProgramDetails(
                programId: program['id'],
                programName: program['name'] ?? 'برنامج',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program['name'] ?? 'بدون اسم',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    if (program['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        program['description'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Colors.green.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
