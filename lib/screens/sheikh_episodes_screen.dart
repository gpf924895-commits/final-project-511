import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/services/lesson_service.dart';
import 'package:new_project/services/sheikh_nav_guard.dart';
import 'package:new_project/services/subcategory_service.dart';
import 'dart:developer' as developer;

class SheikhEpisodesScreen extends StatefulWidget {
  final Map<String, dynamic> program;

  const SheikhEpisodesScreen({super.key, required this.program});

  @override
  State<SheikhEpisodesScreen> createState() => _SheikhEpisodesScreenState();
}

class _SheikhEpisodesScreenState extends State<SheikhEpisodesScreen> {
  final LessonService _lessonService = LessonService();
  final SubcategoryService _subcategoryService = SubcategoryService();

  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = false;
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadEpisodes());
  }

  Future<void> _loadEpisodes() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sheikhUid = authProvider.currentUid;

    if (sheikhUid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load chapters first
      final chapters = await _subcategoryService.listChapters(
        widget.program['id'],
        sheikhUid,
      );

      // Load episodes from all chapters
      final allEpisodes = <Map<String, dynamic>>[];
      for (final chapter in chapters) {
        try {
          final episodes = await _lessonService.listLessons(
            subcatId: widget.program['id'],
            sheikhUid: sheikhUid,
            chapterId: chapter['id'],
          );

          for (final episode in episodes) {
            episode['chapterTitle'] = chapter['title'];
            episode['chapterId'] = chapter['id'];
            allEpisodes.add(episode);
          }
        } catch (e) {
          developer.log(
            'Error loading episodes for chapter ${chapter['id']}: $e',
          );
        }
      }

      // Sort episodes
      allEpisodes.sort((a, b) {
        if (_sortOrder == 'newest') {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
        } else {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime != null && bTime != null) {
            return aTime.compareTo(bTime);
          }
        }
        return 0;
      });

      if (mounted) {
        setState(() {
          _episodes = allEpisodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الحلقات: $e')));
      }
    }
  }

  Widget _buildEpisodeCard(Map<String, dynamic> episode, int index) {
    final hasMedia =
        episode['mediaUrl'] != null &&
        episode['mediaUrl'].toString().isNotEmpty;
    final isPublished = episode['status'] == 'published';
    final isFeatured = episode['featured'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasMedia ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasMedia ? Icons.play_arrow : Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (isFeatured)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
        title: Text(
          '${_getArabicNumber(index + 1)}- ${episode['title'] ?? 'بدون عنوان'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (episode['chapterTitle'] != null)
              Text(
                'من: ${episode['chapterTitle']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPublished ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPublished ? 'منشور' : 'مسودة',
                    style: TextStyle(
                      color: isPublished
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasMedia) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'مقطع صوتي',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: hasMedia
            ? const Icon(Icons.play_circle_outline, color: Colors.green)
            : const Icon(Icons.info_outline, color: Colors.grey),
        onTap: () {
          if (hasMedia) {
            SheikhAuthGuard.validateThenNavigate(
              context,
              () => Navigator.pushNamed(
                context,
                '/sheikh/player',
                arguments: episode,
              ),
            );
          } else {
            _showEpisodeDetails(episode);
          }
        },
      ),
    );
  }

  String _getArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumbers[int.parse(digit)])
        .join('');
  }

  void _showEpisodeDetails(Map<String, dynamic> episode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(episode['title'] ?? 'بدون عنوان'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (episode['abstract'] != null) ...[
                const Text(
                  'النبذة:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(episode['abstract']),
                const SizedBox(height: 16),
              ],
              if (episode['tags'] != null &&
                  (episode['tags'] as List).isNotEmpty) ...[
                const Text(
                  'الوسوم:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text((episode['tags'] as List).join(', ')),
                const SizedBox(height: 16),
              ],
              if (episode['scheduledAt'] != null) ...[
                const Text(
                  'موعد البث:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(episode['scheduledAt'].toString()),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حلقات في هذا البرنامج',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة أبواب ودروس جديدة',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.program['name'] ?? 'البرنامج'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
              });
              _loadEpisodes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('الأحدث')),
              const PopupMenuItem(value: 'oldest', child: Text('الأقدم')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _episodes.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadEpisodes,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _episodes.length,
                  itemBuilder: (context, index) {
                    return _buildEpisodeCard(_episodes[index], index);
                  },
                ),
              ),
      ),
    );
  }
}
