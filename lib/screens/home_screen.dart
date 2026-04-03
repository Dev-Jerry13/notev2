// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animations/animations.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';
import 'folders_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _filterBarController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarShadow = false;

  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _fabController.forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 10;
      if (show != _showAppBarShadow) {
        setState(() => _showAppBarShadow = show);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _filterBarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(noteId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedIds.contains(noteId)) {
        _selectedIds.remove(noteId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(noteId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await _showDeleteDialog(_selectedIds.length);
    if (!confirmed) return;

    for (final id in _selectedIds) {
      await ref.read(notesProvider.notifier).trashNote(id);
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedIds.length} note(s) moved to trash'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteDialog(int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Move to Trash'),
            content: Text(
              'Move $count note${count > 1 ? 's' : ''} to trash?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Move to Trash'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _navigateToNote(NoteModel note) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailScreen(note: note),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _createNewNote() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EditorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up from bottom for new note
          final tween = Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewMode = ref.watch(viewModeProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final pinnedNotes = ref.watch(pinnedNotesProvider);
    final unpinnedNotes = ref.watch(unpinnedNotesProvider);
    final folders = ref.watch(foldersProvider);
    final filter = ref.watch(notesFilterProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        navigationBarColor: theme.scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _buildDrawer(context, folders),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ─── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: _showAppBarShadow ? 4 : 0,
              shadowColor: Colors.black.withOpacity(0.1),
              toolbarHeight: 64,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSelectionMode
                    ? Text(
                        '${_selectedIds.length} selected',
                        key: const ValueKey('selection'),
                        style: theme.textTheme.headlineSmall,
                      )
                    : Text(
                        'Notes',
                        key: const ValueKey('title'),
                        style: theme.textTheme.headlineMedium,
                      ),
              ),
              actions: _isSelectionMode
                  ? _buildSelectionActions()
                  : _buildNormalActions(viewMode),
            ),

            // ─── Search Bar ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SearchBar(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ),

            // ─── Filter Chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterChips(
                selected: filter,
                onSelect: (f) {
                  ref.read(notesFilterProvider.notifier).state = f;
                },
              ),
            ),

            // ─── Empty State ─────────────────────────────────────────────
            if (filteredNotes.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(filter: filter),
              )
            else ...[
              // ─── Pinned Section ────────────────────────────────────────
              if (pinnedNotes.isNotEmpty && filter == NoteFilter.all) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'PINNED'),
                ),
                _buildNoteSection(
                  pinnedNotes,
                  viewMode,
                  startIndex: 0,
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'ALL NOTES',
                    showDivider: true,
                  ),
                ),
              ],

              // ─── Main Notes Section ────────────────────────────────────
              _buildNoteSection(
                filter == NoteFilter.all ? unpinnedNotes : filteredNotes,
                viewMode,
                startIndex: pinnedNotes.length,
              ),
            ],

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),

        // ─── FAB ──────────────────────────────────────────────────────────
        floatingActionButton: AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) => ScaleTransition(
            scale: _fabController,
            child: child,
          ),
          child: _isSelectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: _createNewNote,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New note'),
                  elevation: 4,
                ),
        ),
      ),
    );
  }

  List<Widget> _buildNormalActions(ViewMode viewMode) => [
        // Search
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          tooltip: 'Search',
        ),
        // View toggle
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: viewMode == ViewMode.grid
                ? const Icon(Icons.view_agenda_rounded, key: ValueKey('list'))
                : const Icon(Icons.grid_view_rounded, key: ValueKey('grid')),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(viewModeProvider.notifier).state =
                viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
          },
          tooltip: viewMode == ViewMode.grid ? 'List view' : 'Grid view',
        ),
        // More menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            switch (v) {
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                break;
              case 'trash':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuItem(value: 'trash', child: Text('Trash')),
          ],
        ),
      ];

  List<Widget> _buildSelectionActions() => [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _deleteSelected,
          tooltip: 'Delete',
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _exitSelectionMode,
          tooltip: 'Cancel',
        ),
      ];

  Widget _buildDrawer(BuildContext context, List<FolderModel> folders) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.note_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Samsung Notes',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Nav items
            ListTile(
              leading: const Icon(Icons.note_rounded),
              title: const Text('All Notes'),
              selected: ref.watch(selectedFolderIdProvider) == null,
              selectedColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                ref.read(selectedFolderIdProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_rounded),
              title: const Text('Pinned'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                ref.read(notesFilterProvider.notifier).state = NoteFilter.pinned;
                ref.read(selectedFolderIdProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Folders'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoldersScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Trash'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              },
            ),

            // Folders
            if (folders.isNotEmpty) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'FOLDERS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...folders.map((f) => ListTile(
                    leading: Text(f.icon, style: const TextStyle(fontSize: 20)),
                    title: Text(f.name),
                    selected: ref.watch(selectedFolderIdProvider) == f.id,
                    selectedColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      ref.read(selectedFolderIdProvider.notifier).state = f.id;
                      Navigator.pop(context);
                    },
                  )),
            ],

            const Spacer(),

            // Settings
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(
    List<NoteModel> notes,
    ViewMode viewMode, {
    required int startIndex,
  }) {
    if (viewMode == ViewMode.grid) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Dismissible(
              key: Key(note.id),
              direction: DismissDirection.endToStart,
              background: _buildSwipeBackground(),
              confirmDismiss: (_) => _confirmDismiss(note),
              child: NoteCard(
                note: note,
                index: startIndex + index,
                isSelected: _selectedIds.contains(note.id),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(note.id);
                  } else {
                    _navigateToNote(note);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(note.id);
                  }
                },
              ),
            );
          },
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return Dismissible(
              key: Key(note.id),
              direction: DismissDirection.endToStart,
              background: _buildSwipeBackground(horizontal: true),
              confirmDismiss: (_) => _confirmDismiss(note),
              child: NoteListTile(
                note: note,
                index: startIndex + index,
                isSelected: _selectedIds.contains(note.id),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(note.id);
                  } else {
                    _navigateToNote(note);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(note.id);
                  }
                },
              ),
            );
          },
          childCount: notes.length,
        ),
      );
    }
  }

  Widget _buildSwipeBackground({bool horizontal = false}) {
    return Container(
      margin: horizontal
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDismiss(NoteModel note) async {
    await ref.read(notesProvider.notifier).trashNote(note.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note moved to trash'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              StorageService.restoreNote(note.id);
              ref.read(notesProvider.notifier).refresh();
            },
          ),
        ),
      );
    }
    return true;
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Search notes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.mic_none_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final NoteFilter selected;
  final ValueChanged<NoteFilter> onSelect;

  const _FilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (NoteFilter.all, 'All'),
      (NoteFilter.pinned, 'Pinned'),
      (NoteFilter.recent, 'Recent'),
      (NoteFilter.tagged, 'Tagged'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final (filter, label) = filters[i];
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onSelect(filter),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showDivider;

  const _SectionHeader({required this.title, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDivider) ...[
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final NoteFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, title, subtitle) = switch (filter) {
      NoteFilter.pinned => (
          Icons.push_pin_outlined,
          'No pinned notes',
          'Pin important notes to keep them at the top'
        ),
      NoteFilter.recent => (
          Icons.access_time_rounded,
          'No recent notes',
          'Notes you\'ve edited this week will appear here'
        ),
      NoteFilter.tagged => (
          Icons.label_outline_rounded,
          'No tagged notes',
          'Add tags to your notes to organize them'
        ),
      _ => (
          Icons.note_add_outlined,
          'No notes yet',
          'Tap the + button to create your first note'
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: theme.colorScheme.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
        );
  }
}

// Import storage service for undo in dismiss
import '../services/storage_service.dart';
