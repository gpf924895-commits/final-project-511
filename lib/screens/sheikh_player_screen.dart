import 'package:flutter/material.dart';

class SheikhPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> episode;

  const SheikhPlayerScreen({super.key, required this.episode});

  @override
  State<SheikhPlayerScreen> createState() => _SheikhPlayerScreenState();
}

class _SheikhPlayerScreenState extends State<SheikhPlayerScreen> {
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  final double _totalDuration = 100.0; // Mock duration

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('المشغّل'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('مشاركة (قريباً)')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('إضافة للمفضلة (قريباً)')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Episode artwork placeholder
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Episode title
              Text(
                widget.episode['title'] ?? 'بدون عنوان',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (widget.episode['sheikhName'] != null)
                Text(
                  widget.episode['sheikhName'],
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              // Progress bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.green,
                      inactiveTrackColor: Colors.grey[600],
                      thumbColor: Colors.green,
                      overlayColor: Colors.green.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentPosition,
                      max: _totalDuration,
                      onChanged: (value) {
                        setState(() {
                          _currentPosition = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentPosition),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          _formatTime(_totalDuration),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('السابق (قريباً)')),
                      );
                    },
                    icon: const Icon(Icons.skip_previous, size: 32),
                    color: Colors.white,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isPlaying ? 'تشغيل' : 'إيقاف مؤقت'),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('التالي (قريباً)')),
                      );
                    },
                    icon: const Icon(Icons.skip_next, size: 32),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Additional info
              if (widget.episode['abstract'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نبذة عن الحلقة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.episode['abstract'],
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
