// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/notes_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(isDarkModeProvider);
    final totalNotes = StorageService.totalNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // ─── Appearance ──────────────────────────────────────────────
          _SettingsSection(
            title: 'APPEARANCE',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Switch between light and dark theme',
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    ref.read(isDarkModeProvider.notifier).state = v;
                    await StorageService.setSetting('isDarkMode', v);
                  },
                ),
              ),
            ],
          ),

          // ─── Notes ───────────────────────────────────────────────────
          _SettingsSection(
            title: 'NOTES',
            children: [
              _SettingsTile(
                icon: Icons.note_rounded,
                title: 'Total notes',
                subtitle: '$totalNotes note${totalNotes == 1 ? '' : 's'} stored',
                trailing: null,
              ),
              _SettingsTile(
                icon: Icons.push_pin_outlined,
                title: 'Pinned notes',
                subtitle: '${StorageService.pinnedNotes} pinned',
                trailing: null,
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Locked notes',
                subtitle: '${StorageService.lockedNotes} locked',
                trailing: null,
              ),
            ],
          ),

          // ─── Storage ─────────────────────────────────────────────────
          _SettingsSection(
            title: 'STORAGE',
            children: [
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Trash',
                subtitle:
                    '${StorageService.trashedNotes} note${StorageService.trashedNotes == 1 ? '' : 's'} in trash',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  );
                },
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Empty trash',
                subtitle: 'Permanently delete all trashed notes',
                iconColor: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Empty Trash'),
                      content: const Text(
                          'This will permanently delete all notes in trash. This cannot be undone.'),
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
                          child: const Text('Empty Trash'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await StorageService.emptyTrash();
                    ref.read(notesProvider.notifier).refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trash emptied')),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          // ─── About ───────────────────────────────────────────────────
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Samsung Notes',
                subtitle: 'Version 1.0.0',
                trailing: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
        size: 22,
      ),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

// ─── Trash Screen ─────────────────────────────────────────────────────────────

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trashedNotes = ref.watch(trashedNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (trashedNotes.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Empty Trash'),
                    content: const Text(
                        'Permanently delete all ${trashedNotes.length} notes?'),
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
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await StorageService.emptyTrash();
                  ref.read(notesProvider.notifier).refresh();
                }
              },
              child: Text(
                'Empty',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
        ],
      ),
      body: trashedNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 72,
                    color: theme.colorScheme.onSurface.withOpacity(0.12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleted notes appear here for 30 days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: trashedNotes.length,
              itemBuilder: (context, index) {
                final note = trashedNotes[index];
                return Dismissible(
                  key: Key(note.id),
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.restore_rounded,
                        color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await StorageService.restoreNote(note.id);
                      ref.read(notesProvider.notifier).refresh();
                      return true;
                    } else {
                      await StorageService.deleteNote(note.id);
                      ref.read(notesProvider.notifier).refresh();
                      return true;
                    }
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    title: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore_rounded, size: 20),
                          onPressed: () async {
                            await StorageService.restoreNote(note.id);
                            ref.read(notesProvider.notifier).refresh();
                          },
                          tooltip: 'Restore',
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: index * 30))
                    .fadeIn(duration: 250.ms);
              },
            ),
    );
  }
}

// ─── Folders Screen ────────────────────────────────────────────────────────

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  void _showCreateFolder() {
    final nameController = TextEditingController();
    String selectedEmoji = '📁';

    final emojis = ['📁', '📚', '💼', '🎨', '🏠', '⭐', '❤️', '🎵', '📸', '🌿'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Folder',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),

              // Emoji picker
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: emojis.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedEmoji = emojis[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == emojis[i]
                            ? Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(emojis[i],
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Folder name',
                  labelText: 'Name',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final folder = FolderModel(
                      name: name,
                      icon: selectedEmoji,
                    );
                    await ref.read(foldersProvider.notifier).saveFolder(folder);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolder,
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: folders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 72,
                    color: theme.colorScheme.onSurface.withOpacity(0.12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No folders yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create folders to organize your notes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                final noteCount = notes
                    .where((n) => n.folderId == folder.id && !n.isTrashed)
                    .length;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Text(folder.icon,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(folder.name,
                      style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    '$noteCount note${noteCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Folder'),
                            content: const Text(
                                'Notes in this folder will be moved to root.'),
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
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(foldersProvider.notifier)
                              .deleteFolder(folder.id);
                          ref.read(notesProvider.notifier).refresh();
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete folder',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                )
                    .animate(delay: Duration(milliseconds: index * 30))
                    .fadeIn(duration: 250.ms)
                    .slideX(
                        begin: -0.05,
                        end: 0,
                        duration: 250.ms,
                        curve: Curves.easeOut);
              },
            ),
    );
  }
}

// Import models
import '../models/note_model.dart';
import '../services/storage_service.dart';
