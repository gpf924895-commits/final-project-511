import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/services/sheikh_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSheikhListPage extends StatefulWidget {
  const AdminSheikhListPage({super.key});

  @override
  State<AdminSheikhListPage> createState() => _AdminSheikhListPageState();
}

class _AdminSheikhListPageState extends State<AdminSheikhListPage> {
  final SheikhService _sheikhService = SheikhService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _sheikhs = [];
  List<Map<String, dynamic>> _filteredSheikhs = [];
  bool _isLoading = true;
  bool _fallbackMode = false;
  String? _indexCreateUrl;
  String? _errorMessage;
  bool _showIndexPanel = false;

  @override
  void initState() {
    super.initState();
    _loadSheikhs();
    _searchController.addListener(_filterSheikhs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSheikhs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fallbackMode = false;
      _indexCreateUrl = null;
    });

    try {
      final result = await _sheikhService.listSheikhs(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _sheikhs = result.items;
          _filteredSheikhs = result.items;
          _fallbackMode = result.fallbackMode;
          _indexCreateUrl = result.indexCreateUrl;
          _showIndexPanel =
              result.fallbackMode && result.indexCreateUrl != null;
          _isLoading = false;
        });
      }
    } on SheikhServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل قائمة الشيوخ: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterSheikhs() {
    // If in fallback mode, re-query with search term
    if (_fallbackMode) {
      _loadSheikhs();
      return;
    }

    // Otherwise, client-side filter on already loaded data
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSheikhs = _sheikhs;
      } else {
        _filteredSheikhs = _sheikhs.where((sheikh) {
          final name = (sheikh['name'] ?? '').toLowerCase();
          final email = (sheikh['email'] ?? '').toLowerCase();
          final sheikhId = (sheikh['sheikhId'] ?? '').toString();
          return name.contains(query) ||
              email.contains(query) ||
              sheikhId.contains(query);
        }).toList();
      }
    });
  }

  void _copyToClipboard(String text, {String? message}) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'تم نسخ الرقم الفريد'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _dismissIndexPanel() {
    setState(() {
      _showIndexPanel = false;
    });
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return '-';
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('عرض الشيوخ'),
          centerTitle: true,
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSheikhs,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو البريد أو الرقم الفريد',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Fallback mode badge
            if (_fallbackMode && !_showIndexPanel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'وضع عرض مبسّط — يلزم إنشاء فهرس لتحسين البحث/الفرز',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                    if (_indexCreateUrl != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showIndexPanel = true;
                          });
                        },
                        child: const Text(
                          'تفاصيل',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

            // Index creation panel (dismissible)
            if (_showIndexPanel && _indexCreateUrl != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'فشل تحميل القائمة بالاستعلام الكامل — يحتاج فهرس مركب',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _dismissIndexPanel,
                          tooltip: 'إغلاق',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'يمكنك إنشاء الفهرس المطلوب من خلال Firebase Console:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _copyToClipboard(
                                _indexCreateUrl ?? '',
                                message: 'تم نسخ رابط إنشاء الفهرس',
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('نسخ رابط إنشاء الفهرس'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadSheikhs,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('إعادة المحاولة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _dismissIndexPanel,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('الاستمرار بالعرض المبسّط'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Count and clear search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي: ${_filteredSheikhs.length} شيخ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('مسح البحث'),
                    ),
                ],
              ),
            ),

            // List content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'حدث خطأ غير متوقع',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadSheikhs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _filteredSheikhs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'لا يوجد شيوخ مسجلون بعد'
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredSheikhs.length,
                      itemBuilder: (context, index) {
                        final sheikh = _filteredSheikhs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green,
                                      radius: 24,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sheikh['name'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sheikh['email'] ?? '-',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'القسم:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sheikh['category'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'تاريخ الإنشاء:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(sheikh['createdAt']),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الرقم الفريد:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sheikh['sheikhId'] ?? '-',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: Colors.blue[700],
                                        ),
                                        tooltip: 'نسخ',
                                        onPressed: () => _copyToClipboard(
                                          sheikh['sheikhId'] ?? '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
