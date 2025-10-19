import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SheikhChapterForm extends StatefulWidget {
  final List<Map<String, dynamic>> assignedSubcategories;
  final String sheikhName;
  final Map<String, dynamic>? existingChapter;
  final String? preselectedSubcatId;
  final Function(Map<String, dynamic>) onSave;

  const SheikhChapterForm({
    super.key,
    required this.assignedSubcategories,
    required this.sheikhName,
    this.existingChapter,
    this.preselectedSubcatId,
    required this.onSave,
  });

  @override
  State<SheikhChapterForm> createState() => _SheikhChapterFormState();
}

class _SheikhChapterFormState extends State<SheikhChapterForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  String? _selectedSubcatId;
  DateTime? _scheduledAt;
  String _status = 'draft';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubcatId =
        widget.preselectedSubcatId ?? widget.existingChapter?['subcatId'];

    if (widget.existingChapter != null) {
      _titleController.text = widget.existingChapter?['title'] ?? '';
      _detailsController.text = widget.existingChapter?['details'] ?? '';
      _status = widget.existingChapter?['status'] ?? 'draft';

      if (widget.existingChapter?['scheduledAt'] != null) {
        _scheduledAt = (widget.existingChapter?['scheduledAt'] as dynamic)
            ?.toDate();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
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

  void _handleSave() {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedSubcatId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار القسم')));
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'subcatId': _selectedSubcatId,
      'title': _titleController.text.trim(),
      'sheikhName': widget.sheikhName,
      'scheduledAt': _scheduledAt,
      'details': _detailsController.text.trim(),
      'status': _status,
    };

    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingChapter == null ? 'إضافة باب جديد' : 'تعديل الباب',
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
                  onChanged: (val) => setState(() => _selectedSubcatId = val),
                  validator: (val) => val == null ? 'اختر القسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الباب *',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.right,
                  maxLength: 100,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال عنوان الباب';
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
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات/تفاصيل',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 5,
                  maxLength: 1000,
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
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
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
