import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:new_project/database/firebase_service.dart';

class AddLecturePage extends StatefulWidget {
  final String section;
  const AddLecturePage({super.key, required this.section});

  @override
  State<AddLecturePage> createState() => _AddLecturePageState();
}

class _AddLecturePageState extends State<AddLecturePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _videoPath;
  String? _videoFileName;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    try {
      final subcategories = await _firebaseService.getSubcategoriesBySection(widget.section);
      setState(() {
        _subcategories = subcategories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الفئات الفرعية: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoPath = result.files.single.path;
          _videoFileName = result.files.single.name;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار الفيديو: $_videoFileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الفيديو: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveLecture() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة العنوان والوصف'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.addLecture(
        title: title,
        description: description,
        videoPath: _videoPath,
        section: widget.section,
        subcategoryId: _selectedSubcategoryId,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة محاضرة - ${widget.section}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // عنوان المحاضرة
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المحاضرة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 16),
                  
                  // اختيار الفئة الفرعية
                  if (_subcategories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedSubcategoryId,
                      decoration: const InputDecoration(
                        labelText: 'الفئة الفرعية (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text('اختر الفئة الفرعية'),
                      items: _subcategories.map((subcategory) {
                        return DropdownMenuItem<String>(
                          value: subcategory['id'],
                          child: Text(subcategory['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategoryId = value;
                        });
                      },
                    ),
                  if (_subcategories.isNotEmpty)
                    const SizedBox(height: 16),
                  
                  // وصف المحاضرة
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف المحاضرة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'أدخل وصف تفصيلي للمحاضرة...',
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 16),
                  
                  // اختيار الفيديو
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.video_library, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'الفيديو (اختياري)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_videoFileName != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _videoFileName!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _videoPath = null;
                                      _videoFileName = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        
                        ElevatedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_videoFileName == null 
                              ? 'اختر فيديو' 
                              : 'تغيير الفيديو'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // زر الحفظ
                  ElevatedButton.icon(
                    onPressed: _saveLecture,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'حفظ المحاضرة',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ملاحظة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'ملاحظة: يمكنك إضافة المحاضرة بدون فيديو وإضافته لاحقاً عند التعديل',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
