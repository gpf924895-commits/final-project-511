import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:new_project/services/lesson_service.dart';
import 'dart:io';

class SheikhLessonForm extends StatefulWidget {
  final List<Map<String, dynamic>> assignedSubcategories;
  final String sheikhName;
  final String sheikhUid;
  final Map<String, dynamic>? existingLesson;
  final String? preselectedSubcatId;
  final String? preselectedChapterId;
  final Function(Map<String, dynamic>) onSave;

  const SheikhLessonForm({
    super.key,
    required this.assignedSubcategories,
    required this.sheikhName,
    required this.sheikhUid,
    this.existingLesson,
    this.preselectedSubcatId,
    this.preselectedChapterId,
    required this.onSave,
  });

  @override
  State<SheikhLessonForm> createState() => _SheikhLessonFormState();
}

class _SheikhLessonFormState extends State<SheikhLessonForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _tagsController = TextEditingController();
  final _lessonService = LessonService();

  String? _selectedSubcatId;
  String? _selectedChapterId;
  List<Map<String, dynamic>> _chapters = [];
  bool _loadingChapters = false;

  DateTime? _scheduledAt;
  DateTime? _recordedAt;
  DateTime? _publishAt;
  String _status = 'draft';

  File? _mediaFile;
  String? _existingMediaUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubcatId =
        widget.preselectedSubcatId ?? widget.existingLesson?['subcatId'];
    _selectedChapterId =
        widget.preselectedChapterId ?? widget.existingLesson?['chapterId'];

    if (widget.existingLesson != null) {
      _titleController.text = widget.existingLesson?['title'] ?? '';
      _abstractController.text = widget.existingLesson?['abstract'] ?? '';

      final tags = widget.existingLesson?['tags'];
      if (tags is List) {
        _tagsController.text = tags.join(', ');
      }

      _status = widget.existingLesson?['status'] ?? 'draft';
      _existingMediaUrl = widget.existingLesson?['mediaUrl'];

      if (widget.existingLesson?['scheduledAt'] != null) {
        _scheduledAt = (widget.existingLesson?['scheduledAt'] as dynamic)
            ?.toDate();
      }
      if (widget.existingLesson?['recordedAt'] != null) {
        _recordedAt = (widget.existingLesson?['recordedAt'] as dynamic)
            ?.toDate();
      }
      if (widget.existingLesson?['publishAt'] != null) {
        _publishAt = (widget.existingLesson?['publishAt'] as dynamic)?.toDate();
      }
    }

    if (_selectedSubcatId != null) {
      _loadChapters(_selectedSubcatId ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters(String subcatId) async {
    setState(() => _loadingChapters = true);
    try {
      final chapters = await _lessonService.listChapters(
        subcatId: subcatId,
        sheikhUid: widget.sheikhUid,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _loadingChapters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingChapters = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الأبواب: $e')));
      }
    }
  }

  Future<void> _pickScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickRecordedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_recordedAt ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _recordedAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickPublishDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_publishAt ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _publishAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickMediaFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'wav', 'avi', 'm4a', 'aac'],
    );

    if (result != null && mounted) {
      setState(() {
        _mediaFile = File(result.files.single.path ?? '');
      });
    }
  }

  Future<String?> _uploadMedia() async {
    if (_mediaFile == null) return _existingMediaUrl;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      String? mediaUrl;

      await for (final progress in _lessonService.uploadMedia(
        file: _mediaFile ?? File(''),
        lessonId: tempId,
        sheikhUid: widget.sheikhUid,
      )) {
        if (mounted) {
          setState(() => _uploadProgress = progress.progress);
        }

        if (progress.isDone) {
          mediaUrl = progress.downloadUrl;
          break;
        }

        if (progress.error != null) {
          throw Exception(progress.error);
        }
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      return mediaUrl;
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل رفع الملف: $e')));
      }
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedSubcatId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار القسم')));
      return;
    }

    if (_selectedChapterId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الباب')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload media if new file selected
      final mediaUrl = await _uploadMedia();

      // Parse tags
      final tagsList = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Determine publishedAt
      DateTime? publishedAt;
      if (_status == 'published') {
        publishedAt = _publishAt ?? DateTime.now();
      }

      final data = {
        'subcatId': _selectedSubcatId,
        'chapterId': _selectedChapterId,
        'title': _titleController.text.trim(),
        'sheikhName': widget.sheikhName,
        'abstract': _abstractController.text.trim(),
        'tags': tagsList,
        'scheduledAt': _scheduledAt,
        'recordedAt': _recordedAt,
        'publishAt': _publishAt,
        'publishedAt': publishedAt,
        'status': _status,
        'mediaUrl': mediaUrl,
        'mediaType': _mediaFile != null
            ? _mediaFile?.path.split('.').last ?? 'unknown'
            : null,
        'mediaSize': _mediaFile != null ? _mediaFile?.lengthSync() : null,
      };

      widget.onSave(data);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLesson == null ? 'إضافة درس جديد' : 'تعديل الدرس',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSubcatId,
                  decoration: const InputDecoration(
                    labelText: 'القسم *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.assignedSubcategories
                      .map<DropdownMenuItem<String>>((subcat) {
                        return DropdownMenuItem<String>(
                          value: subcat['id'],
                          child: Text(subcat['name'] ?? 'بدون اسم'),
                        );
                      })
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSubcatId = val;
                        _selectedChapterId = null;
                        _chapters = [];
                      });
                      _loadChapters(val);
                    }
                  },
                  validator: (val) => val == null ? 'اختر القسم' : null,
                ),
                const SizedBox(height: 16),
                if (_loadingChapters)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_chapters.isEmpty && _selectedSubcatId != null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد أبواب في هذا القسم',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (_chapters.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedChapterId,
                    decoration: const InputDecoration(
                      labelText: 'الباب *',
                      border: OutlineInputBorder(),
                    ),
                    items: _chapters.map<DropdownMenuItem<String>>((chapter) {
                      return DropdownMenuItem<String>(
                        value: chapter['id'],
                        child: Text(chapter['title'] ?? 'بدون عنوان'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedChapterId = val),
                    validator: (val) => val == null ? 'اختر الباب' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الدرس *',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.right,
                  maxLength: 120,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال عنوان الدرس';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.sheikhName,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشيخ',
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _abstractController,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عن الدرس',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'وسوم (افصل بفواصل)',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: فقه, عبادات, صلاة',
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickScheduledDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الإقامة/البث',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _scheduledAt == null
                          ? 'اختياري'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(_scheduledAt ?? DateTime.now()),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickRecordedDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ التسجيل',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _recordedAt == null
                          ? 'اختياري'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(_recordedAt ?? DateTime.now()),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickPublishDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ النشر',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _publishAt == null
                          ? 'اختياري (افتراضي: الآن عند النشر)'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(_publishAt ?? DateTime.now()),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: _publishAt == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رفع المقطع (اختياري)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_mediaFile == null && _existingMediaUrl == null)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading || _isSaving
                                  ? null
                                  : _pickMediaFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('اختر ملف صوت/فيديو'),
                            ),
                          )
                        else ...[
                          if (_mediaFile != null)
                            Text(
                              'الملف: ${_mediaFile?.path.split(Platform.pathSeparator).last ?? 'unknown'}',
                              style: const TextStyle(fontSize: 14),
                            )
                          else if (_existingMediaUrl != null)
                            const Text(
                              'يوجد ملف مرفوع مسبقًا',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          if (_isUploading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: _uploadProgress),
                            const SizedBox(height: 8),
                            Text(
                              'جارٍ الرفع: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else if (_mediaFile != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _mediaFile = null),
                              icon: const Icon(Icons.close),
                              label: const Text('إزالة'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                    DropdownMenuItem(value: 'published', child: Text('منشور')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving || _isUploading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving || _isUploading
                            ? null
                            : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
