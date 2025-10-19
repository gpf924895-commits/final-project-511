import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'package:new_project/widgets/sheikh_guard.dart';

class AddLectureForm extends StatefulWidget {
  final String categoryKey;
  final String categoryNameAr;

  const AddLectureForm({
    super.key,
    required this.categoryKey,
    required this.categoryNameAr,
  });

  @override
  State<AddLectureForm> createState() => _AddLectureFormState();
}

class _AddLectureFormState extends State<AddLectureForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  bool _hasEndTime = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheikhGuard(
      routeName: '/sheikh/add/form',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFE4E5D3),
          appBar: AppBar(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            title: Text('إضافة محاضرة - ${widget.categoryNameAr}'),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Consumer<LectureProvider>(
                builder: (context, lectureProvider, child) {
                  return TextButton(
                    onPressed: lectureProvider.isLoading ? null : _saveLecture,
                    child: lectureProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'حفظ',
                            style: TextStyle(color: Colors.white),
                          ),
                  );
                },
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Info Card
                  _buildCategoryInfoCard(),
                  const SizedBox(height: 24),

                  // Basic Information
                  _buildSectionTitle('المعلومات الأساسية'),
                  const SizedBox(height: 12),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),

                  // Time Information
                  _buildSectionTitle('معلومات الوقت'),
                  const SizedBox(height: 12),
                  _buildStartTimeField(),
                  const SizedBox(height: 16),
                  _buildEndTimeToggle(),
                  if (_hasEndTime) ...[
                    const SizedBox(height: 16),
                    _buildEndTimeField(),
                  ],
                  const SizedBox(height: 24),

                  // Location Information
                  _buildSectionTitle('معلومات الموقع (اختياري)'),
                  const SizedBox(height: 12),
                  _buildLocationField(),
                  const SizedBox(height: 24),

                  // Media Information
                  _buildSectionTitle('الملفات المرفقة (اختياري)'),
                  const SizedBox(height: 12),
                  _buildAudioUrlField(),
                  const SizedBox(height: 16),
                  _buildVideoUrlField(),
                  const SizedBox(height: 32),

                  // Error Message
                  Consumer<LectureProvider>(
                    builder: (context, lectureProvider, child) {
                      if (lectureProvider.errorMessage != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200] ?? Colors.red),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lectureProvider.errorMessage ?? 'خطأ غير معروف',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.category, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فئة المحاضرة',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    widget.categoryNameAr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade700,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'عنوان المحاضرة *',
        hintText: 'أدخل عنوان المحاضرة',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'عنوان المحاضرة مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'وصف المحاضرة',
        hintText: 'أدخل وصف المحاضرة (اختياري)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
      ),
    );
  }

  Widget _buildStartTimeField() {
    return InkWell(
      onTap: _selectStartDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'وقت البداية *',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _selectedStartDate != null && _selectedStartTime != null
                        ? '${_formatDate(_selectedStartDate ?? DateTime.now())} - ${_formatTime(_selectedStartTime ?? TimeOfDay.now())}'
                        : 'اختر وقت البداية',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildEndTimeToggle() {
    return Row(
      children: [
        Checkbox(
          value: _hasEndTime,
          onChanged: (value) {
            setState(() {
              _hasEndTime = value ?? false;
            });
          },
        ),
        const Text('تحديد وقت انتهاء'),
      ],
    );
  }

  Widget _buildEndTimeField() {
    return InkWell(
      onTap: _selectEndDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'وقت الانتهاء',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _selectedEndDate != null && _selectedEndTime != null
                        ? '${_formatDate(_selectedEndDate ?? DateTime.now())} - ${_formatTime(_selectedEndTime ?? TimeOfDay.now())}'
                        : 'اختر وقت الانتهاء',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'الموقع',
        hintText: 'أدخل موقع المحاضرة',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildAudioUrlField() {
    return TextFormField(
      controller: _audioUrlController,
      decoration: InputDecoration(
        labelText: 'رابط الصوت',
        hintText: 'أدخل رابط الملف الصوتي',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.audiotrack),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
          return 'رابط غير صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildVideoUrlField() {
    return TextFormField(
      controller: _videoUrlController,
      decoration: InputDecoration(
        labelText: 'رابط الفيديو',
        hintText: 'أدخل رابط الفيديو',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.videocam),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
          return 'رابط غير صحيح';
        }
        return null;
      },
    );
  }

  Future<void> _selectStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedStartTime ?? TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedStartDate = date;
          _selectedStartTime = time;
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? (_selectedStartDate ?? DateTime.now()),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedEndTime ?? TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedEndDate = date;
          _selectedEndTime = time;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  Future<void> _saveLecture() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedStartDate == null || _selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد وقت البداية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lectureProvider = Provider.of<LectureProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في بيانات المستخدم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedStartDate?.year ?? DateTime.now().year,
      _selectedStartDate?.month ?? DateTime.now().month,
      _selectedStartDate?.day ?? DateTime.now().day,
      _selectedStartTime?.hour ?? TimeOfDay.now().hour,
      _selectedStartTime?.minute ?? TimeOfDay.now().minute,
    );

    // Validate start time is in the future
    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون وقت البداية في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime? endDateTime;
    if (_hasEndTime && _selectedEndDate != null && _selectedEndTime != null) {
      endDateTime = DateTime(
        _selectedEndDate?.year ?? DateTime.now().year,
        _selectedEndDate?.month ?? DateTime.now().month,
        _selectedEndDate?.day ?? DateTime.now().day,
        _selectedEndTime?.hour ?? TimeOfDay.now().hour,
        _selectedEndTime?.minute ?? TimeOfDay.now().minute,
      );

      // Validate end time is after start time
      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب أن يكون وقت النهاية بعد وقت البداية'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Prepare media data with URL validation
    Map<String, dynamic>? media;
    if (_audioUrlController.text.isNotEmpty ||
        _videoUrlController.text.isNotEmpty) {
      media = {};
      if (_audioUrlController.text.isNotEmpty) {
        final audioUrl = _audioUrlController.text.trim();
        if (!_isValidUrl(audioUrl)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('صيغة رابط الصوت غير صحيحة'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        media['audioUrl'] = audioUrl;
      }
      if (_videoUrlController.text.isNotEmpty) {
        final videoUrl = _videoUrlController.text.trim();
        if (!_isValidUrl(videoUrl)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('صيغة رابط الفيديو غير صحيحة'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        media['videoUrl'] = videoUrl;
      }
    }

    // Prepare location data
    Map<String, dynamic>? location;
    if (_locationController.text.isNotEmpty) {
      location = {'label': _locationController.text.trim()};
    }

    final success = await lectureProvider.addSheikhLecture(
      sheikhId: authProvider.currentUid ?? '',
      sheikhName: authProvider.currentUser?['name'] ?? 'شيخ',
      categoryKey: widget.categoryKey,
      categoryNameAr: widget.categoryNameAr,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      location: location,
      media: media,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المحاضرة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
