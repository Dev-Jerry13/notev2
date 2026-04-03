// lib/screens/detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../services/export_service.dart';
import 'editor_screen.dart';
import 'lock_screen.dart';

/// Read-only view of a note — transitions from card via Hero
class DetailScreen extends ConsumerStatefulWidget {
  final NoteModel note;

  const DetailScreen({super.key, required this.note});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    if (!widget.note.isLocked) _isUnlocked = true;
  }

  Future<void> _tryUnlock() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          correctHash: widget.note.lockHash,
          noteTitle: widget.note.title,
        ),
      ),
    );
    if (result == true) setState(() => _isUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final note = widget.note;
    final cardColor = getNoteColor(note.color, isDark);

    // Show lock screen prompt if locked
    if (note.isLocked && !_isUnlocked) {
      return Scaffold(
        backgroundColor: cardColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.25),
              ).animate().scale(
                    begin: const Offset(0.7, 0.7),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),
              Text(
                note.title.isEmpty ? 'Locked Note' : note.title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This note is protected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _tryUnlock,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    return Hero(
      tag: 'note_${note.id}',
      flightShuttleBuilder: (_, animation, __, ___, ____) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, child) => Material(
            color: Colors.transparent,
            child: child,
          ),
          child: Container(color: cardColor),
        );
      },
      child: Scaffold(
        backgroundColor: cardColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => EditorScreen(note: note),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                );
              },
              tooltip: 'Edit',
            ),
            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) async {
                switch (v) {
                  case 'pin':
                    await ref
                        .read(notesProvider.notifier)
                        .togglePin(note.id);
                    if (mounted) Navigator.pop(context);
                    break;
                  case 'export_txt':
                    await ExportService.exportAsTxt(note);
                    break;
                  case 'export_pdf':
                    await ExportService.exportAsPdf(note);
                    break;
                  case 'delete':
                    await ref
                        .read(notesProvider.notifier)
                        .trashNote(note.id);
                    if (mounted) Navigator.pop(context);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        note.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(note.isPinned ? 'Unpin' : 'Pin note'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_txt',
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Export as TXT'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Move to trash',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title
                  if (note.title.isNotEmpty)
                    Text(
                      note.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 10),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('MMMM d, yyyy  •  h:mm a')
                            .format(note.updatedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

                  // Tags
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: note.tags
                          .map((t) => _SmallTagChip(tag: t))
                          .toList(),
                    ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                  ],

                  const SizedBox(height: 20),

                  Divider(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    height: 1,
                  ),

                  const SizedBox(height: 20),

                  // Content
                  if (note.content.isNotEmpty)
                    SelectableText(
                      note.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.75,
                        letterSpacing: 0.1,
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms),

                  if (note.content.isEmpty && note.title.isEmpty)
                    Text(
                      'No content',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Image attachments
                  if (note.attachments.any((a) => a.type == 'image')) ...[
                    const SizedBox(height: 24),
                    _AttachmentImagesView(
                      images: note.attachments
                          .where((a) => a.type == 'image')
                          .toList(),
                    ),
                  ],

                  // File attachments
                  if (note.attachments.any((a) => a.type != 'image')) ...[
                    const SizedBox(height: 24),
                    _AttachmentFilesView(
                      files: note.attachments
                          .where((a) => a.type != 'image')
                          .toList(),
                    ),
                  ],

                  // Word count footer
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      '${note.wordCount} word${note.wordCount == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.25),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTagChip extends StatelessWidget {
  final String tag;
  const _SmallTagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AttachmentImagesView extends StatelessWidget {
  final List<NoteAttachment> images;
  const _AttachmentImagesView({required this.images});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMAGES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: images.length,
          itemBuilder: (_, i) {
            return GestureDetector(
              onTap: () => _openImageFull(context, images[i]),
              child: Hero(
                tag: 'img_${images[i].id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(images[i].path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ],
    );
  }

  void _openImageFull(BuildContext context, NoteAttachment img) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageScreen(attachment: img),
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  final NoteAttachment attachment;
  const _FullImageScreen({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          attachment.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Hero(
        tag: 'img_${attachment.id}',
        child: InteractiveViewer(
          child: Center(
            child: Image.file(
              File(attachment.path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentFilesView extends StatelessWidget {
  final List<NoteAttachment> files;
  const _AttachmentFilesView({required this.files});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTACHMENTS',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 10),
        ...files.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;

          IconData icon;
          Color iconColor;
          switch (f.type) {
            case 'pdf':
              icon = Icons.picture_as_pdf_outlined;
              iconColor = Colors.red.shade400;
              break;
            case 'doc':
              icon = Icons.description_outlined;
              iconColor = Colors.blue.shade400;
              break;
            default:
              icon = Icons.text_snippet_outlined;
              iconColor = Colors.grey;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _fmtBytes(f.sizeBytes),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: i * 50))
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.05, duration: 250.ms, curve: Curves.easeOut);
        }),
      ],
    );
  }

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
