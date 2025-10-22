import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/hierarchy_provider.dart';
import 'package:new_project/widgets/sheikh_guard.dart';

class SheikhHierarchyManageScreen extends StatefulWidget {
  const SheikhHierarchyManageScreen({super.key});

  @override
  State<SheikhHierarchyManageScreen> createState() =>
      _SheikhHierarchyManageScreenState();
}

class _SheikhHierarchyManageScreenState
    extends State<SheikhHierarchyManageScreen> {
  String _selectedSection = 'fiqh';
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  final List<Map<String, String>> _sections = [
    {'key': 'fiqh', 'name': 'الفقه'},
    {'key': 'hadith', 'name': 'الحديث'},
    {'key': 'seerah', 'name': 'السيرة'},
    {'key': 'tafsir', 'name': 'التفسير'},
  ];

  @override
  Widget build(BuildContext context) {
    return SheikhGuard(
      routeName: '/sheikh/hierarchy/manage',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFE4E5D3),
          appBar: AppBar(
            title: const Text('إدارة التصنيفات'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Section Picker
              _buildSectionPicker(),
              const Divider(height: 1),
              // Content based on selection
              Expanded(
                child: _selectedCategoryId == null
                    ? _buildCategoriesList()
                    : _buildSubcategoriesList(),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  Widget _buildSectionPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر القسم:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSection,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _sections.map((section) {
              return DropdownMenuItem(
                value: section['key'],
                child: Text(section['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSection = value!;
                _selectedCategoryId = null;
                _selectedCategoryName = null;
              });
              _loadCategories();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Consumer<HierarchyProvider>(
      builder: (context, hierarchyProvider, child) {
        if (hierarchyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (hierarchyProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  hierarchyProvider.errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCategories,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final categories = hierarchyProvider.categories;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد فئات في هذا القسم',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة فئة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
    );
  }

  Widget _buildSubcategoriesList() {
    return Consumer<HierarchyProvider>(
      builder: (context, hierarchyProvider, child) {
        if (hierarchyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (hierarchyProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  hierarchyProvider.errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSubcategories,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final subcategories = hierarchyProvider.subcategories;

        return Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(bottom: BorderSide(color: Colors.green[200]!)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedCategoryName = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'فئات فرعية - $_selectedCategoryName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Subcategories list
            Expanded(
              child: subcategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد فئات فرعية في هذه الفئة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddSubcategoryDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة فئة فرعية جديدة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: subcategories.length,
                      itemBuilder: (context, index) {
                        final subcategory = subcategories[index];
                        return _buildSubcategoryCard(subcategory);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          radius: 24,
          child: const Icon(Icons.category, color: Colors.white, size: 20),
        ),
        title: Text(
          category['name'] ?? 'بدون اسم',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: category['description'] != null
            ? Text(
                category['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryId = category['id'];
                  _selectedCategoryName = category['name'];
                });
                _loadSubcategories();
              },
              icon: const Icon(Icons.subdirectory_arrow_right),
              tooltip: 'عرض الفئات الفرعية',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _showDeleteCategoryDialog(category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          radius: 24,
          child: const Icon(
            Icons.subdirectory_arrow_right,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          subcategory['name'] ?? 'بدون اسم',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: subcategory['description'] != null
            ? Text(
                subcategory['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditSubcategoryDialog(subcategory);
            } else if (value == 'delete') {
              _showDeleteSubcategoryDialog(subcategory);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('تعديل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _selectedCategoryId == null
          ? _showAddCategoryDialog
          : _showAddSubcategoryDialog,
      icon: const Icon(Icons.add),
      label: Text(
        _selectedCategoryId == null ? 'إضافة فئة' : 'إضافة فئة فرعية',
      ),
      backgroundColor: Colors.green,
    );
  }

  // ==================== Data Loading ====================

  void _loadCategories() {
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );
    hierarchyProvider.loadCategoriesBySection(_selectedSection);
  }

  void _loadSubcategories() {
    if (_selectedCategoryId == null) return;
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );
    hierarchyProvider.loadSubcategoriesByCategory(_selectedCategoryId!);
  }

  // ==================== Category Dialogs ====================

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final orderController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة فئة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _addCategory(
                nameController,
                descriptionController,
                orderController,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final nameController = TextEditingController(text: category['name'] ?? '');
    final descriptionController = TextEditingController(
      text: category['description'] ?? '',
    );
    final orderController = TextEditingController(
      text: (category['order'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الفئة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _editCategory(
                category['id'],
                nameController,
                descriptionController,
                orderController,
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الفئة "${category['name']}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _deleteCategory(category['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Subcategory Dialogs ====================

  void _showAddSubcategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final orderController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة فئة فرعية جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة الفرعية *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _addSubcategory(
                nameController,
                descriptionController,
                orderController,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubcategoryDialog(Map<String, dynamic> subcategory) {
    final nameController = TextEditingController(
      text: subcategory['name'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: subcategory['description'] ?? '',
    );
    final orderController = TextEditingController(
      text: (subcategory['order'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الفئة الفرعية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة الفرعية *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _editSubcategory(
                subcategory['id'],
                nameController,
                descriptionController,
                orderController,
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSubcategoryDialog(Map<String, dynamic> subcategory) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف الفئة الفرعية "${subcategory['name']}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _deleteSubcategory(subcategory['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Actions ====================

  Future<void> _addCategory(
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController orderController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.addCategory(
      section: _selectedSection,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      order: int.tryParse(orderController.text) ?? 0,
      createdBy: authProvider.currentUid ?? '',
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الفئة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editCategory(
    String categoryId,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController orderController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.updateCategory(
      categoryId: categoryId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      order: int.tryParse(orderController.text) ?? 0,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الفئة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.deleteCategory(categoryId);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الفئة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    }
  }

  Future<void> _addSubcategory(
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController orderController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة الفرعية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار فئة أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.addSubcategory(
      section: _selectedSection,
      categoryId: _selectedCategoryId!,
      categoryName: _selectedCategoryName!,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      order: int.tryParse(orderController.text) ?? 0,
      createdBy: authProvider.currentUid ?? '',
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الفئة الفرعية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editSubcategory(
    String subcategoryId,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController orderController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة الفرعية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.updateSubcategory(
      subcategoryId: subcategoryId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      order: int.tryParse(orderController.text) ?? 0,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الفئة الفرعية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSubcategories();
    }
  }

  Future<void> _deleteSubcategory(String subcategoryId) async {
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );

    final success = await hierarchyProvider.deleteSubcategory(subcategoryId);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الفئة الفرعية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSubcategories();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
}
