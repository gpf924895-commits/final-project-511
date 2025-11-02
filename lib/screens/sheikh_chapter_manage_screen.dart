import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/widgets/sheikh_chapter_form.dart';

class SheikhChapterManageScreen extends StatefulWidget {
  const SheikhChapterManageScreen({super.key});

  @override
  State<SheikhChapterManageScreen> createState() =>
      _SheikhChapterManageScreenState();
}

class _SheikhChapterManageScreenState extends State<SheikhChapterManageScreen> {
  final SubcategoryService _subcategoryService = SubcategoryService();
  // Removed FirebaseFirestore - use LocalRepository via services
  List<Map<String, dynamic>> _assignedSubcategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkAccessAndLoad());
  }

  Future<void> _checkAccessAndLoad() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    final role = authProvider.currentUser?['role'];

    if (sheikhUid == null || role != 'sheikh') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('هذا القسم للشيوخ فقط.')));
      }
      return;
    }

    try {
      final subcats = await _subcategoryService.listAssignedSubcategories(
        sheikhUid,
      );
      if (mounted) {
        setState(() {
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

  Future<void> _handleSave(Map<String, dynamic> data) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;
    if (sheikhUid == null) return;

    final subcatId = data['subcatId'];
    if (subcatId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار القسم')));
      return;
    }

    try {
      // TODO: Implement chapter creation in LocalRepository
      // For now, use SubcategoryService which is stubbed
      await _subcategoryService.createChapter(
        subcatId,
        sheikhUid,
        data['title'] ?? '',
        data,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الباب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sheikhName = authProvider.currentUser?['name'] ?? 'شيخ';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('إضافة باب'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _assignedSubcategories.isEmpty
            ? const Center(child: Text('لم يتم تعيين أقسام لك بعد.'))
            : SafeArea(
                child: SheikhChapterForm(
                  assignedSubcategories: _assignedSubcategories,
                  sheikhName: sheikhName,
                  existingChapter: null,
                  preselectedSubcatId: null,
                  onSave: _handleSave,
                ),
              ),
      ),
    );
  }
}
