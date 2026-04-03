// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Shared date/time formatting helpers used across the app
class NoteDate {
  NoteDate._();

  /// Short relative label for note cards: "Just now", "3m ago", "Mon", "Apr 2"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return DateFormat('h:mm a').format(date);
    if (diff.inDays < 7)      return DateFormat('EEE').format(date);
    if (diff.inDays < 365)    return DateFormat('MMM d').format(date);
    return DateFormat('MMM d, y').format(date);
  }

  /// Long format used in editor metadata bar
  static String long(DateTime date) =>
      DateFormat('MMM d, yyyy  h:mm a').format(date);

  /// Short date only
  static String short(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  /// Returns true if two dates are on the same calendar day
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// lib/utils/file_utils.dart (appended below as a second class in same file)

/// File size and type helpers
class FileUtils {
  FileUtils._();

  /// Human-readable file size
  static String formatBytes(int bytes) {
    if (bytes < 1024)        return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns a broad type string from a file extension
  static String typeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': case 'heic':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'doc': case 'docx':
        return 'doc';
      case 'xls': case 'xlsx':
        return 'spreadsheet';
      default:
        return 'txt';
    }
  }

  /// Icon + color pair for a file type in the attachment list
  static ({String label, String colorHex}) typeInfo(String type) {
    return switch (type) {
      'pdf'        => (label: 'PDF',   colorHex: '#F44336'),
      'doc'        => (label: 'DOC',   colorHex: '#2196F3'),
      'spreadsheet'=> (label: 'XLS',   colorHex: '#4CAF50'),
      'image'      => (label: 'IMG',   colorHex: '#9C27B0'),
      _            => (label: 'TXT',   colorHex: '#607D8B'),
    };
  }
}
