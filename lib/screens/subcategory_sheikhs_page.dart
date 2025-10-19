import 'package:flutter/material.dart';
import 'package:new_project/services/subcategory_service.dart';
import '../widgets/app_drawer.dart';
import 'sheikh_chapters_page.dart';

class SubcategorySheikhsPage extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;
  final String section;
  final bool isDarkMode;
  final Function(bool)? toggleTheme;

  const SubcategorySheikhsPage({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.section,
    required this.isDarkMode,
    this.toggleTheme,
  });

  @override
  State<SubcategorySheikhsPage> createState() => _SubcategorySheikhsPageState();
}

class _SubcategorySheikhsPageState extends State<SubcategorySheikhsPage> {
  final SubcategoryService _service = SubcategoryService();
  List<Map<String, dynamic>> _sheikhs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadSheikhs());
  }

  Future<void> _loadSheikhs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sheikhs = await _service.listSheikhs(widget.subcategoryId);
      setState(() {
        _sheikhs = sheikhs;
        _isLoading = false;
      });
    } on SubcategoryServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });

      // If index is needed, show additional info in debug console
      if (e.needsIndex && e.indexUrl != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'يرجى إنشاء الفهرس المطلوب في قاعدة البيانات. راجع وحدة التحكم للحصول على الرابط.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: Text(widget.subcategoryName),
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
            ),
            if (widget.toggleTheme != null)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
          ],
        ),
        drawer: widget.toggleTheme != null
            ? AppDrawer(toggleTheme: widget.toggleTheme!)
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSheikhs,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : _sheikhs.isEmpty
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
                      'لا يوجد مشايخ مكلفون بهذا الباب بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مشايخ هذا الباب',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _sheikhs.length,
                        itemBuilder: (context, index) {
                          final sheikh = _sheikhs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: widget.isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 30,
                                child: Text(
                                  (sheikh['displayName'] ?? 'ش').substring(
                                    0,
                                    1,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                sheikh['displayName'] ?? 'شيخ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.green,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SheikhChaptersPage(
                                      subcategoryId: widget.subcategoryId,
                                      subcategoryName: widget.subcategoryName,
                                      sheikhUid: sheikh['sheikhUid'],
                                      sheikhName:
                                          sheikh['displayName'] ?? 'شيخ',
                                      section: widget.section,
                                      isDarkMode: widget.isDarkMode,
                                      toggleTheme: widget.toggleTheme,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
