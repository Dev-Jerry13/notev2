// lib/models/note_model.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note_model.g.dart';

/// Represents the display color/accent of a note card
@HiveType(typeId: 2)
enum NoteColor {
  @HiveField(0)
  none,
  @HiveField(1)
  yellow,
  @HiveField(2)
  blue,
  @HiveField(3)
  green,
  @HiveField(4)
  pink,
  @HiveField(5)
  purple,
  @HiveField(6)
  orange,
}

/// Represents an attached file/image within a note
@HiveType(typeId: 1)
class NoteAttachment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path; // local file path

  @HiveField(3)
  final String type; // 'image', 'pdf', 'doc', 'txt'

  @HiveField(4)
  final int sizeBytes;

  @HiveField(5)
  final DateTime addedAt;

  NoteAttachment({
    String? id,
    required this.name,
    required this.path,
    required this.type,
    required this.sizeBytes,
    DateTime? addedAt,
  })  : id = id ?? const Uuid().v4(),
        addedAt = addedAt ?? DateTime.now();
}

/// Main Note model
@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content; // Plain text content

  @HiveField(3)
  String? richContent; // JSON string for flutter_quill delta

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  bool isLocked;

  @HiveField(8)
  String? lockHash; // SHA256 hash of PIN

  @HiveField(9)
  String? folderId;

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  List<NoteAttachment> attachments;

  @HiveField(12)
  NoteColor color;

  @HiveField(13)
  bool isArchived;

  @HiveField(14)
  bool isTrashed;

  @HiveField(15)
  DateTime? trashedAt;

  NoteModel({
    String? id,
    this.title = '',
    this.content = '',
    this.richContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.lockHash,
    this.folderId,
    List<String>? tags,
    List<NoteAttachment>? attachments,
    this.color = NoteColor.none,
    this.isArchived = false,
    this.isTrashed = false,
    this.trashedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        attachments = attachments ?? [];

  /// Returns a preview snippet of the note content (max 150 chars)
  String get preview {
    final text = content.trim();
    if (text.isEmpty) return 'No additional text';
    return text.length > 150 ? '${text.substring(0, 150)}...' : text;
  }

  /// Whether this note has any content
  bool get hasContent => title.isNotEmpty || content.isNotEmpty;

  /// Number of words in content
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Creates a deep copy of this note
  NoteModel copyWith({
    String? title,
    String? content,
    String? richContent,
    bool? isPinned,
    bool? isLocked,
    String? lockHash,
    String? folderId,
    List<String>? tags,
    List<NoteAttachment>? attachments,
    NoteColor? color,
    bool? isArchived,
    bool? isTrashed,
    DateTime? trashedAt,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      richContent: richContent ?? this.richContent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      lockHash: lockHash ?? this.lockHash,
      folderId: folderId ?? this.folderId,
      tags: tags ?? List.from(this.tags),
      attachments: attachments ?? List.from(this.attachments),
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
    );
  }
}

/// Folder/Category model
@HiveType(typeId: 3)
class FolderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // emoji or icon name

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  int colorValue; // color as int

  FolderModel({
    String? id,
    required this.name,
    this.icon = '📁',
    DateTime? createdAt,
    this.colorValue = 0xFF6750A4,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}
