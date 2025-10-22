import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'package:new_project/provider/hierarchy_provider.dart';
import 'package:new_project/widgets/sheikh_guard.dart';
import 'package:new_project/utils/youtube_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AddLectureForm extends StatefulWidget {
  const AddLectureForm({super.key});

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

  // YouTube validation state
  String? _extractedVideoId;
  bool _isValidYouTubeUrl = false;
  String? _youtubeValidationError;

  // Hierarchy selection state
  String? _selectedSection;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;

  final List<Map<String, String>> _sections = [
    {'key': 'fiqh', 'name': 'الفقه'},
    {'key': 'hadith', 'name': 'الحديث'},
    {'key': 'seerah', 'name': 'السيرة'},
    {'key': 'tafsir', 'name': 'التفسير'},
  ];

  @override
  void initState() {
    super.initState();
    // Load categories for the selected section when form opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hierarchyProvider = Provider.of<HierarchyProvider>(
        context,
        listen: false,
      );
      if (hierarchyProvider.selectedSection != null) {
        hierarchyProvider.loadCategoriesBySection(
          hierarchyProvider.selectedSection!,
        );
      }
    });
  }

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
            title: const Text('إضافة محاضرة'),
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
                  // Hierarchy Selection
                  _buildSectionTitle('اختيار التصنيف'),
                  const SizedBox(height: 12),
                  _buildHierarchySelection(),
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
                            border: Border.all(
                              color: Colors.red[200] ?? Colors.red,
                            ),
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
                                  lectureProvider.errorMessage ??
                                      'خطأ غير معروف',
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

  Widget _buildHierarchySelection() {
    return Consumer<HierarchyProvider>(
      builder: (context, hierarchyProvider, child) {
        final selectedSection = hierarchyProvider.selectedSection;
        if (selectedSection == null) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'يرجى اختيار القسم أولاً من صفحة اختيار الفئة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'اختيار التصنيف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Section Display (non-editable)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'القسم: ${_getSectionNameAr(selectedSection)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Category Selection
                Consumer<HierarchyProvider>(
                  builder: (context, hierarchyProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'الفئة *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                      items: hierarchyProvider.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'] as String?,
                          child: Text(category['name'] ?? 'بدون اسم'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedCategoryName = hierarchyProvider.categories
                              .firstWhere((cat) => cat['id'] == value)['name'];
                          _selectedSubcategoryId = null;
                          _selectedSubcategoryName = null;
                        });
                        if (value != null) {
                          _loadSubcategories(value);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Subcategory Selection (Optional)
                Consumer<HierarchyProvider>(
                  builder: (context, hierarchyProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedSubcategoryId,
                      decoration: const InputDecoration(
                        labelText: 'الفئة الفرعية (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('بدون فئة فرعية'),
                        ),
                        ...hierarchyProvider.subcategories.map((subcategory) {
                          return DropdownMenuItem<String>(
                            value: subcategory['id'] as String?,
                            child: Text(subcategory['name'] ?? 'بدون اسم'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategoryId = value;
                          if (value != null) {
                            _selectedSubcategoryName = hierarchyProvider
                                .subcategories
                                .firstWhere(
                                  (sub) => sub['id'] == value,
                                )['name'];
                          } else {
                            _selectedSubcategoryName = null;
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _videoUrlController,
          decoration: InputDecoration(
            labelText: 'رابط الفيديو (يوتيوب)',
            hintText: 'أدخل رابط فيديو يوتيوب',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.videocam),
            suffixIcon: _videoUrlController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _isValidYouTubeUrl ? Icons.check_circle : Icons.error,
                      color: _isValidYouTubeUrl ? Colors.green : Colors.red,
                    ),
                    onPressed: _validateYouTubeUrl,
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _isValidYouTubeUrl = false;
              _extractedVideoId = null;
              _youtubeValidationError = null;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!YouTubeUtils.isValidYouTubeUrl(value)) {
                return 'رابط يوتيوب غير صحيح';
              }
              if (_youtubeValidationError != null) {
                return _youtubeValidationError;
              }
            }
            return null;
          },
        ),
        if (_youtubeValidationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red[200] ?? Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _youtubeValidationError!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isValidYouTubeUrl && _extractedVideoId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green[200] ?? Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رابط يوتيوب صحيح - معرف الفيديو: $_extractedVideoId',
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _previewVideo,
                  child: const Text('معاينة'),
                ),
              ],
            ),
          ),
        ],
      ],
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

  void _validateYouTubeUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isValidYouTubeUrl = false;
        _extractedVideoId = null;
        _youtubeValidationError = null;
      });
      return;
    }

    final result = YouTubeUtils.validateAndExtract(url);
    setState(() {
      _isValidYouTubeUrl = result['isValid'];
      _extractedVideoId = result['videoId'];
      _youtubeValidationError = result['error'];
    });
  }

  void _previewVideo() {
    if (_extractedVideoId == null) return;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'معاينة الفيديو',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: YoutubePlayer(
                      controller: YoutubePlayerController(
                        initialVideoId: _extractedVideoId!,
                        flags: const YoutubePlayerFlags(
                          autoPlay: false,
                          mute: false,
                          isLive: false,
                          forceHD: true,
                          enableCaption: true,
                        ),
                      ),
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.green,
                      onReady: () {
                        // Video is ready to play
                      },
                      onEnded: (data) {
                        // Video ended
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Hierarchy Helper Methods ====================

  String _getSectionNameAr(String section) {
    final sectionNames = {
      'fiqh': 'الفقه',
      'hadith': 'الحديث',
      'seerah': 'السيرة',
      'tafsir': 'التفسير',
    };
    return sectionNames[section] ?? section;
  }

  void _loadCategories(String section) {
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );
    hierarchyProvider.loadCategoriesBySection(section);
  }

  void _loadSubcategories(String categoryId) {
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );
    hierarchyProvider.loadSubcategoriesByCategory(categoryId);
  }

  Future<void> _saveLecture() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Get selected section from provider
    final hierarchyProvider = Provider.of<HierarchyProvider>(
      context,
      listen: false,
    );
    final selectedSection = hierarchyProvider.selectedSection;

    // Validate hierarchy selection
    if (selectedSection == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار القسم والفئة'),
          backgroundColor: Colors.red,
        ),
      );
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

    // Validate YouTube URL if provided
    if (_videoUrlController.text.isNotEmpty) {
      final result = YouTubeUtils.validateAndExtract(
        _videoUrlController.text.trim(),
      );
      if (!result['isValid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'رابط يوتيوب غير صحيح'),
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
        final videoId = YouTubeUtils.extractVideoId(videoUrl);
        media['videoUrl'] = videoUrl;
        if (videoId != null) {
          media['videoId'] = videoId;
        }
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
      section: selectedSection!,
      categoryId: _selectedCategoryId!,
      categoryName: _selectedCategoryName!,
      subcategoryId: _selectedSubcategoryId,
      subcategoryName: _selectedSubcategoryName,
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
