// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';

/// Service that handles all local Hive storage operations
class StorageService {
  static const String notesBoxName = 'notes';
  static const String foldersBoxName = 'folders';
  static const String settingsBoxName = 'settings';

  static late Box<NoteModel> _notesBox;
  static late Box<FolderModel> _foldersBox;
  static late Box<dynamic> _settingsBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NoteAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(NoteColorAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FolderModelAdapter());
    }

    // Open boxes
    _notesBox = await Hive.openBox<NoteModel>(notesBoxName);
    _foldersBox = await Hive.openBox<FolderModel>(foldersBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
  }

  // ─── Notes ───────────────────────────────────────────────────────────────

  /// Returns all notes (not trashed)
  static List<NoteModel> getAllNotes() {
    return _notesBox.values
        .where((n) => !n.isTrashed)
        .toList()
      ..sort((a, b) {
        // Pinned notes first, then by updatedAt
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  /// Returns all trashed notes
  static List<NoteModel> getTrashedNotes() {
    return _notesBox.values
        .where((n) => n.isTrashed)
        .toList()
      ..sort((a, b) => b.trashedAt!.compareTo(a.trashedAt!));
  }

  /// Returns notes in a specific folder
  static List<NoteModel> getNotesByFolder(String folderId) {
    return _notesBox.values
        .where((n) => n.folderId == folderId && !n.isTrashed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Returns notes by tag
  static List<NoteModel> getNotesByTag(String tag) {
    return _notesBox.values
        .where((n) => n.tags.contains(tag) && !n.isTrashed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Returns notes matching a search query
  static List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();
    final lower = query.toLowerCase();
    return _notesBox.values
        .where((n) =>
            !n.isTrashed &&
            (n.title.toLowerCase().contains(lower) ||
                n.content.toLowerCase().contains(lower) ||
                n.tags.any((t) => t.toLowerCase().contains(lower))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Save or update a note
  static Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note);
  }

  /// Delete a note permanently
  static Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  /// Move note to trash
  static Future<void> trashNote(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      note.isTrashed = true;
      note.trashedAt = DateTime.now();
      await note.save();
    }
  }

  /// Restore note from trash
  static Future<void> restoreNote(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      note.isTrashed = false;
      note.trashedAt = null;
      await note.save();
    }
  }

  /// Empty trash permanently
  static Future<void> emptyTrash() async {
    final trashed = _notesBox.values.where((n) => n.isTrashed).toList();
    for (final note in trashed) {
      await _notesBox.delete(note.id);
    }
  }

  /// Listenable for real-time updates to notes box
  static ValueListenable<Box<NoteModel>> get notesListenable =>
      _notesBox.listenable();

  // ─── Folders ─────────────────────────────────────────────────────────────

  /// Returns all folders sorted by name
  static List<FolderModel> getAllFolders() {
    return _foldersBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Save or update a folder
  static Future<void> saveFolder(FolderModel folder) async {
    await _foldersBox.put(folder.id, folder);
  }

  /// Delete folder (notes are moved to root)
  static Future<void> deleteFolder(String folderId) async {
    // Unassign notes from this folder
    final notesInFolder =
        _notesBox.values.where((n) => n.folderId == folderId).toList();
    for (final note in notesInFolder) {
      note.folderId = null;
      await note.save();
    }
    await _foldersBox.delete(folderId);
  }

  static ValueListenable<Box<FolderModel>> get foldersListenable =>
      _foldersBox.listenable();

  // ─── Settings ────────────────────────────────────────────────────────────

  static T? getSetting<T>(String key) => _settingsBox.get(key) as T?;

  static Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static ValueListenable<Box<dynamic>> get settingsListenable =>
      _settingsBox.listenable();

  // ─── Statistics ──────────────────────────────────────────────────────────

  static int get totalNotes =>
      _notesBox.values.where((n) => !n.isTrashed).length;
  static int get pinnedNotes =>
      _notesBox.values.where((n) => n.isPinned && !n.isTrashed).length;
  static int get lockedNotes =>
      _notesBox.values.where((n) => n.isLocked && !n.isTrashed).length;
  static int get trashedNotes =>
      _notesBox.values.where((n) => n.isTrashed).length;
}
