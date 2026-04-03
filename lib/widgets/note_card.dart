// lib/widgets/note_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';

/// Returns the background color for a note based on its color setting and theme
Color getNoteColor(NoteColor color, bool isDark) {
  if (isDark) {
    switch (color) {
      case NoteColor.yellow:
        return AppColors.noteYellowDark;
      case NoteColor.blue:
        return AppColors.noteBlueDark;
      case NoteColor.green:
        return AppColors.noteGreenDark;
      case NoteColor.pink:
        return AppColors.notePinkDark;
      case NoteColor.purple:
        return AppColors.notePurpleDark;
      case NoteColor.orange:
        return AppColors.noteOrangeDark;
      default:
        return AppColors.darkCard;
    }
  } else {
    switch (color) {
      case NoteColor.yellow:
        return AppColors.noteYellow;
      case NoteColor.blue:
        return AppColors.noteBlue;
      case NoteColor.green:
        return AppColors.noteGreen;
      case NoteColor.pink:
        return AppColors.notePink;
      case NoteColor.purple:
        return AppColors.notePurple;
      case NoteColor.orange:
        return AppColors.noteOrange;
      default:
        return AppColors.lightCard;
    }
  }
}

/// Grid-view note card with hero animation support
class NoteCard extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.index = 0,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = getNoteColor(widget.note.color, isDark);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress();
        },
        child: Hero(
          tag: 'note_${widget.note.id}',
          flightShuttleBuilder: (_, animation, __, ___, ____) {
            return AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Material(
                color: Colors.transparent,
                child: child,
              ),
              child: _buildCardContent(context, cardColor, isDark),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildCardContent(context, cardColor, isDark),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 40))
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildCardContent(
      BuildContext context, Color cardColor, bool isDark) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pin indicator + title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.note.title.isEmpty
                            ? 'Untitled'
                            : widget.note.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.note.title.isEmpty
                              ? theme.colorScheme.onSurface.withOpacity(0.4)
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.note.isPinned) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                    if (widget.note.isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ],
                ),

                // Content preview
                if (!widget.note.isLocked && widget.note.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.note.preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                if (widget.note.isLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Tap to unlock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Image attachment preview
                if (!widget.note.isLocked &&
                    widget.note.attachments
                        .any((a) => a.type == 'image')) ...[
                  const SizedBox(height: 8),
                  _ImagePreviewStrip(
                    attachments: widget.note.attachments
                        .where((a) => a.type == 'image')
                        .take(3)
                        .toList(),
                  ),
                ],

                // Tags
                if (widget.note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.note.tags.take(3).map((tag) {
                      return _TagChip(tag: tag);
                    }).toList(),
                  ),
                ],

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _formatDate(widget.note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selection overlay
          if (widget.isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      return DateFormat('h:mm a').format(date);
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE').format(date);
    }
    return DateFormat('MMM d').format(date);
  }
}

/// Horizontal strip of image previews in a note card
class _ImagePreviewStrip extends StatelessWidget {
  final List<NoteAttachment> attachments;

  const _ImagePreviewStrip({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: attachments.map((a) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: attachments.last == a ? 0 : 4,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  a.path,
                  fit: BoxFit.cover,
                  height: 56,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.withOpacity(0.2),
                    child: const Icon(Icons.image_rounded, size: 20),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact tag chip for note cards
class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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

// ─── List-view variant ───────────────────────────────────────────────────────

/// Compact horizontal list-view note tile
class NoteListTile extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final int index;

  const NoteListTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = getNoteColor(note.color, isDark);

    return Hero(
      tag: 'note_${note.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress();
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Color accent dot
                if (note.color != NoteColor.none)
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Untitled' : note.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isPinned)
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          if (note.isLocked)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color:
                                    theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                      if (!note.isLocked && note.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            note.preview,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Text(
                  _formatDate(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),

                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 30))
        .fadeIn(duration: 250.ms)
        .slideX(begin: -0.05, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('h:mm a').format(date);
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }
}
