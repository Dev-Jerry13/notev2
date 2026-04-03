// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Date Formatting ──────────────────────────────────────────────────────────

/// Returns a human-friendly relative or absolute date string
String formatNoteDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && now.day == date.day) {
    return DateFormat('h:mm a').format(date);
  }
  if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
    return 'Yesterday';
  }
  if (diff.inDays < 7) return DateFormat('EEEE').format(date); // "Monday"
  if (date.year == now.year) return DateFormat('MMM d').format(date);
  return DateFormat('MMM d, y').format(date);
}

/// Long format for detail screen
String formatNoteDateLong(DateTime date) {
  return DateFormat('MMMM d, yyyy  •  h:mm a').format(date);
}

// ─── File Size ────────────────────────────────────────────────────────────────

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ─── String Extensions ────────────────────────────────────────────────────────

extension StringX on String {
  /// Truncates string to [maxLength] with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }

  /// Capitalizes first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Strips Markdown-style formatting for plain preview
  String get plainText {
    return replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // bold
        .replaceAll(RegExp(r'_(.+?)_'), r'$1') // italic
        .replaceAll(RegExp(r'__(.+?)__'), r'$1') // underline
        .replaceAll(RegExp(r'#{1,6}\s'), '') // headings
        .replaceAll(RegExp(r'^\s*[-•]\s', multiLine: true), '') // bullets
        .replaceAll(RegExp(r'^\s*\d+\.\s', multiLine: true), '') // numbered
        .trim();
  }
}

// ─── Color Utilities ──────────────────────────────────────────────────────────

/// Darken a color by a given factor (0.0–1.0)
Color darken(Color color, [double factor = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - factor).clamp(0.0, 1.0))
      .toColor();
}

/// Lighten a color by a given factor (0.0–1.0)
Color lighten(Color color, [double factor = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + factor).clamp(0.0, 1.0))
      .toColor();
}

// ─── Debouncer ────────────────────────────────────────────────────────────────

import 'dart:async';

/// Debouncer class for auto-save and search
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
