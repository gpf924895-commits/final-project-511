import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'package:new_project/widgets/sheikh_lesson_form.dart';

class SheikhLessonUploadScreen extends StatefulWidget {
  const SheikhLessonUploadScreen({super.key});

  @override
  State<SheikhLessonUploadScreen> createState() =>
      _SheikhLessonUploadScreenState();
}

class _SheikhLessonUploadScreenState extends State<SheikhLessonUploadScreen> {
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
    final chapterId = data['chapterId'];

    if (subcatId == null || chapterId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار القسم والباب')));
      return;
    }

    try {
      // TODO: Implement lesson creation in LocalRepository
      // For now, show message that this feature is not yet supported
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('إنشاء الدروس غير مدعوم حالياً في الوضع المحلي'),
          ),
        );
      }
      // Navigator.pop(context, false); // Return failure for now
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
    final sheikhUid = authProvider.currentUid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('إضافة درس'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _assignedSubcategories.isEmpty
            ? const Center(child: Text('لم يتم تعيين أقسام لك بعد.'))
            : SafeArea(
                child: SheikhLessonForm(
                  assignedSubcategories: _assignedSubcategories,
                  sheikhName: sheikhName,
                  sheikhUid: sheikhUid,
                  existingLesson: null,
                  preselectedSubcatId: null,
                  preselectedChapterId: null,
                  onSave: _handleSave,
                ),
              ),
      ),
    );
  }
}
