import 'dart:core';

class YouTubeUtils {
  /// Extract video ID from various YouTube URL formats
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // Remove any whitespace
    url = url.trim();

    // Handle different YouTube URL formats
    final patterns = [
      // Standard watch URLs: https://www.youtube.com/watch?v=VIDEO_ID
      RegExp(
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})',
      ),
      // Short URLs: https://youtu.be/VIDEO_ID
      RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})'),
      // Embed URLs: https://www.youtube.com/embed/VIDEO_ID
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
      // Shorts URLs: https://www.youtube.com/shorts/VIDEO_ID
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final videoId = match.group(1);
        if (videoId != null && _isValidVideoId(videoId)) {
          return videoId;
        }
      }
    }

    return null;
  }

  /// Validate if a string is a valid YouTube video ID
  static bool _isValidVideoId(String videoId) {
    // YouTube video IDs are exactly 11 characters long
    // and contain only alphanumeric characters, hyphens, and underscores
    return videoId.length == 11 &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(videoId);
  }

  /// Check if a URL is a valid YouTube URL
  static bool isValidYouTubeUrl(String url) {
    if (url.isEmpty) return false;

    final youtubePatterns = [
      RegExp(r'^https?:\/\/(www\.)?youtube\.com\/watch\?v=[a-zA-Z0-9_-]{11}'),
      RegExp(r'^https?:\/\/(www\.)?youtu\.be\/[a-zA-Z0-9_-]{11}'),
      RegExp(r'^https?:\/\/(www\.)?youtube\.com\/embed\/[a-zA-Z0-9_-]{11}'),
      RegExp(r'^https?:\/\/(www\.)?youtube\.com\/shorts\/[a-zA-Z0-9_-]{11}'),
    ];

    return youtubePatterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Get YouTube embed URL from video ID
  static String getEmbedUrl(String videoId) {
    return 'https://www.youtube.com/embed/$videoId';
  }

  /// Get YouTube thumbnail URL from video ID
  static String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  /// Get YouTube watch URL from video ID
  static String getWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Validate and extract video ID with error message
  static Map<String, dynamic> validateAndExtract(String url) {
    if (url.isEmpty) {
      return {
        'isValid': false,
        'error': 'الرجاء إدخال رابط يوتيوب',
        'videoId': null,
      };
    }

    if (!isValidYouTubeUrl(url)) {
      return {
        'isValid': false,
        'error': 'رابط يوتيوب غير صحيح. يرجى التأكد من الرابط',
        'videoId': null,
      };
    }

    final videoId = extractVideoId(url);
    if (videoId == null) {
      return {
        'isValid': false,
        'error': 'لا يمكن استخراج معرف الفيديو من الرابط',
        'videoId': null,
      };
    }

    return {'isValid': true, 'error': null, 'videoId': videoId};
  }
}
