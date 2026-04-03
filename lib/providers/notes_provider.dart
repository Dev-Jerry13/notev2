// lib/providers/notes_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';

// ─── View Mode ───────────────────────────────────────────────────────────────

/// Grid or list view toggle
enum ViewMode { grid, list }

final viewModeProvider = StateProvider<ViewMode>(
  (ref) => ViewMode.grid,
);

// ─── Search ──────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Filter ──────────────────────────────────────────────────────────────────

enum NoteFilter { all, pinned, recent, tagged, archived }

final notesFilterProvider = StateProvider<NoteFilter>((ref) => NoteFilter.all);

final selectedTagProvider = StateProvider<String?>((ref) => null);
final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

// ─── Theme ───────────────────────────────────────────────────────────────────

final isDarkModeProvider = StateProvider<bool>((ref) {
  return StorageService.getSetting<bool>('isDarkMode') ?? false;
});

// ─── Notes Notifier ──────────────────────────────────────────────────────────

/// Manages the complete list of notes with CRUD operations
class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier() : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    state = StorageService.getAllNotes();
  }

  /// Refresh notes from storage
  void refresh() {
    state = StorageService.getAllNotes();
  }

  /// Add or update a note
  Future<void> saveNote(NoteModel note) async {
    await StorageService.saveNote(note);
    _loadNotes();
  }

  /// Move note to trash
  Future<void> trashNote(String noteId) async {
    await StorageService.trashNote(noteId);
    _loadNotes();
  }

  /// Permanently delete
  Future<void> deleteNote(String noteId) async {
    await StorageService.deleteNote(noteId);
    _loadNotes();
  }

  /// Toggle pin status
  Future<void> togglePin(String noteId) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    final updated = note.copyWith(isPinned: !note.isPinned);
    await StorageService.saveNote(updated);
    _loadNotes();
  }

  /// Toggle lock status
  Future<void> toggleLock(String noteId, {String? pinHash}) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    final updated = note.copyWith(
      isLocked: !note.isLocked,
      lockHash: !note.isLocked ? pinHash : null,
    );
    await StorageService.saveNote(updated);
    _loadNotes();
  }

  /// Update note color
  Future<void> updateColor(String noteId, NoteColor color) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    final updated = note.copyWith(color: color);
    await StorageService.saveNote(updated);
    _loadNotes();
  }

  /// Move note to folder
  Future<void> moveToFolder(String noteId, String? folderId) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    final updated = note.copyWith(folderId: folderId);
    await StorageService.saveNote(updated);
    _loadNotes();
  }

  /// Add tag to note
  Future<void> addTag(String noteId, String tag) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    if (note.tags.contains(tag)) return;
    final updated = note.copyWith(tags: [...note.tags, tag]);
    await StorageService.saveNote(updated);
    _loadNotes();
  }

  /// Remove tag from note
  Future<void> removeTag(String noteId, String tag) async {
    final idx = state.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state[idx];
    final updated = note.copyWith(
      tags: note.tags.where((t) => t != tag).toList(),
    );
    await StorageService.saveNote(updated);
    _loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>(
  (ref) => NotesNotifier(),
);

// ─── Filtered Notes ──────────────────────────────────────────────────────────

/// Returns notes filtered and searched based on current state
final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(notesFilterProvider);
  final selectedTag = ref.watch(selectedTagProvider);
  final selectedFolder = ref.watch(selectedFolderIdProvider);

  List<NoteModel> result = notes;

  // Apply folder filter
  if (selectedFolder != null) {
    result = result.where((n) => n.folderId == selectedFolder).toList();
  }

  // Apply tag filter
  if (selectedTag != null) {
    result = result.where((n) => n.tags.contains(selectedTag)).toList();
  }

  // Apply main filter
  switch (filter) {
    case NoteFilter.pinned:
      result = result.where((n) => n.isPinned).toList();
      break;
    case NoteFilter.recent:
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      result = result.where((n) => n.updatedAt.isAfter(cutoff)).toList();
      break;
    case NoteFilter.archived:
      result = result.where((n) => n.isArchived).toList();
      break;
    default:
      break;
  }

  // Apply search
  if (query.isNotEmpty) {
    final lower = query.toLowerCase();
    result = result
        .where((n) =>
            n.title.toLowerCase().contains(lower) ||
            n.content.toLowerCase().contains(lower) ||
            n.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();
  }

  return result;
});

// Pinned notes sub-list
final pinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(filteredNotesProvider).where((n) => n.isPinned).toList();
});

// Un-pinned notes sub-list
final unpinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  return ref.watch(filteredNotesProvider).where((n) => !n.isPinned).toList();
});

// All unique tags across all notes
final allTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesProvider);
  final Set<String> tags = {};
  for (final note in notes) {
    tags.addAll(note.tags);
  }
  return tags.toList()..sort();
});

// ─── Folders Notifier ────────────────────────────────────────────────────────

class FoldersNotifier extends StateNotifier<List<FolderModel>> {
  FoldersNotifier() : super([]) {
    state = StorageService.getAllFolders();
  }

  void refresh() {
    state = StorageService.getAllFolders();
  }

  Future<void> saveFolder(FolderModel folder) async {
    await StorageService.saveFolder(folder);
    refresh();
  }

  Future<void> deleteFolder(String folderId) async {
    await StorageService.deleteFolder(folderId);
    refresh();
  }
}

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<FolderModel>>(
  (ref) => FoldersNotifier(),
);

// ─── Trashed Notes ───────────────────────────────────────────────────────────

final trashedNotesProvider = Provider<List<NoteModel>>((ref) {
  // Watch notes to trigger rebuild on changes
  ref.watch(notesProvider);
  return StorageService.getTrashedNotes();
});
