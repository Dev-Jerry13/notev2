# Architecture Overview

## Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION                         │
│  screens/          widgets/           theme/                │
│  ─────────         ────────           ──────                │
│  home_screen       note_card          app_theme             │
│  editor_screen     animated_widgets   AppColors             │
│  detail_screen     common_widgets     TextTheme             │
│  search_screen                                              │
│  lock_screen                                                │
│  settings_screen                                            │
│  folders_screen                                             │
│  trash_screen                                               │
│  splash_screen                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │ watches / reads
┌──────────────────────────▼──────────────────────────────────┐
│                     STATE MANAGEMENT                        │
│                    providers/ (Riverpod)                    │
│                                                             │
│  notesProvider          → StateNotifier<List<NoteModel>>    │
│  foldersProvider        → StateNotifier<List<FolderModel>>  │
│  filteredNotesProvider  → computed (search + filter)        │
│  pinnedNotesProvider    → computed slice                    │
│  unpinnedNotesProvider  → computed slice                    │
│  allTagsProvider        → computed tag set                  │
│  trashedNotesProvider   → computed trash list               │
│  viewModeProvider       → StateProvider<ViewMode>           │
│  searchQueryProvider    → StateProvider<String>             │
│  notesFilterProvider    → StateProvider<NoteFilter>         │
│  isDarkModeProvider     → StateProvider<bool>               │
│  selectedFolderProvider → StateProvider<String?>            │
│  selectedTagProvider    → StateProvider<String?>            │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────────┐
│                        SERVICES                             │
│                                                             │
│  StorageService          ExportService                      │
│  ───────────────         ─────────────                      │
│  getAllNotes()            exportAsTxt(note)                  │
│  saveNote(note)           exportAsPdf(note)                  │
│  trashNote(id)                                              │
│  deleteNote(id)                                             │
│  restoreNote(id)                                            │
│  emptyTrash()                                               │
│  getAllFolders()                                             │
│  saveFolder(folder)                                         │
│  getSetting(key)                                            │
│  setSetting(key, val)                                       │
└──────────────────────────┬──────────────────────────────────┘
                           │ persists to
┌──────────────────────────▼──────────────────────────────────┐
│                     DATA / MODELS                           │
│                                                             │
│  NoteModel (Hive typeId: 0)                                 │
│    id, title, content, richContent                          │
│    createdAt, updatedAt                                     │
│    isPinned, isLocked, lockHash                             │
│    folderId, tags[], attachments[]                          │
│    color, isArchived, isTrashed, trashedAt                  │
│                                                             │
│  NoteAttachment (typeId: 1)                                 │
│    id, name, path, type, sizeBytes, addedAt                 │
│                                                             │
│  NoteColor enum (typeId: 2)                                 │
│    none|yellow|blue|green|pink|purple|orange                │
│                                                             │
│  FolderModel (typeId: 3)                                    │
│    id, name, icon, createdAt, colorValue                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Hive Binary Storage                    │   │
│  │  Box<NoteModel>    Box<FolderModel>    Box<dynamic> │   │
│  │   "notes"           "folders"          "settings"  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Screen Flow

```
SplashScreen (1.8s)
      │  FadeTransition
      ▼
HomeScreen ──── Drawer ──── FoldersScreen
    │    │                       │
    │    └── SearchScreen        └── (create/delete folders)
    │
    │  PageRouteBuilder (FadeTransition)
    ▼
DetailScreen ──────────────────────────────────
    │  (if locked)    │  FloatingActionButton
    ▼                 ▼
LockScreen       EditorScreen
                      │  auto-save (1.5s debounce)
                      ▼
                  StorageService.saveNote()
```

## Animation Inventory

| Location | Widget/Technique | Duration | Purpose |
|---|---|---|---|
| `note_card.dart` | `Hero` | native | Card → screen transition |
| `note_card.dart` | `AnimationController` scale 0.96 | 100ms | Press feedback |
| `note_card.dart` | `flutter_animate` stagger | 40ms×index | Cards cascade in |
| `home_screen.dart` | `PageRouteBuilder` fade+slideY | 350ms | New note screen |
| `home_screen.dart` | `ScaleTransition` FAB | 300ms | FAB entrance |
| `home_screen.dart` | `AnimatedSwitcher` | 200ms | Title ↔ selection |
| `home_screen.dart` | `FilterChip` AnimatedContainer | 200ms | Chip highlight |
| `editor_screen.dart` | `SizeTransition` toolbar | 250ms | Toolbar show/hide |
| `editor_screen.dart` | `FadeTransition` save indicator | 400ms | Auto-save ping |
| `detail_screen.dart` | `Hero` | native | Shared element |
| `detail_screen.dart` | `flutter_animate` stagger | 80–220ms | Content reveal |
| `lock_screen.dart` | `ScaleTransition` keys | 80ms | Dial press |
| `lock_screen.dart` | `Transform.translate` shake | 400ms | Wrong PIN |
| `lock_screen.dart` | `flutter_animate` elasticOut | 400ms | Icon entrance |
| `splash_screen.dart` | `flutter_animate` elasticOut | 600ms | Logo bounce |
| `main.dart` | `MaterialApp.themeAnimationDuration` | 350ms | Theme switch |
