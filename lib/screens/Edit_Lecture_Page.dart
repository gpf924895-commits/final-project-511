import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:new_project/database/firebase_service.dart';

class EditLecturePage extends StatefulWidget {
  final String? section;
  const EditLecturePage({super.key, this.section});

  @override
  State<EditLecturePage> createState() => _EditLecturePageState();
}

class _EditLecturePageState extends State<EditLecturePage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _lectures = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLectures();
  }

  Future<void> _loadLectures() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> lectures;
      if (widget.section != null) {
        lectures = await _firebaseService.getLecturesBySection(widget.section!);
      } else {
        lectures = await _firebaseService.getAllLectures();
      }
      
      setState(() {
        _lectures = lectures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('خطأ في تحميل المحاضرات: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _openEditDialog(Map<String, dynamic> lecture) {
    final TextEditingController titleController = 
        TextEditingController(text: lecture['title']);
    final TextEditingController descriptionController = 
        TextEditingController(text: lecture['description']);
    
    String? videoPath = lecture['video_path'];
    String? videoFileName = videoPath?.split('/').last;
    
    String? selectedSubcategoryId = lecture['subcategory_id'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل المحاضرة', textAlign: TextAlign.right),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المحاضرة',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'وصف المحاضرة',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  
                  // اختيار الفئة الفرعية
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _firebaseService.getSubcategoriesBySection(lecture['section']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedSubcategoryId,
                            decoration: const InputDecoration(
                              labelText: 'الفئة الفرعية (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('اختر الفئة الفرعية'),
                            items: snapshot.data!.map((subcategory) {
                              return DropdownMenuItem<String>(
                                value: subcategory['id'],
                                child: Text(subcategory['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedSubcategoryId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  
                  // قسم الفيديو
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'الفيديو:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        
                        if (videoFileName != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.video_file, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    videoFileName!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      videoPath = null;
                                      videoFileName = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'لا يوجد فيديو',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        
                        const SizedBox(height: 8),
                        
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.video,
                              allowMultiple: false,
                            );

                            if (result != null && result.files.single.path != null) {
                              setDialogState(() {
                                videoPath = result.files.single.path;
                                videoFileName = result.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(
                            videoFileName == null ? 'اختر فيديو' : 'تغيير الفيديو',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
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
                onPressed: () async {
                  final title = titleController.text.trim();
                  final description = descriptionController.text.trim();
                  
                  if (title.isEmpty || description.isEmpty) {
                    _showMessage('يرجى تعبئة جميع الحقول', Colors.orange);
                    return;
                  }
                  
                  final result = await _firebaseService.updateLecture(
                    id: lecture['id'],
                    title: title,
                    description: description,
                    videoPath: videoPath,
                    section: lecture['section'],
                    subcategoryId: selectedSubcategoryId,
                  );
                  
                  Navigator.pop(context);
                  
                  if (result['success']) {
                    _showMessage('✅ ${result['message']}', Colors.green);
                    _loadLectures();
                  } else {
                    _showMessage(result['message'], Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section != null 
            ? 'تعديل المحاضرات - ${widget.section}'
            : 'تعديل المحاضرات'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLectures,
            tooltip: 'تحديث',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lectures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد محاضرات بعد',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'قم بإضافة محاضرات أولاً',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = _lectures[index];
                    final hasVideo = lecture['video_path'] != null;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(
                            hasVideo ? Icons.video_library : Icons.book,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        title: Text(
                          lecture['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lecture['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  lecture['section'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (hasVideo) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.videocam, size: 14, color: Colors.green.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'يحتوي على فيديو',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _openEditDialog(lecture),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
