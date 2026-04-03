// lib/screens/editor_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;

  const EditorScreen({super.key, this.note});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocus;
  late FocusNode _contentFocus;
  late AnimationController _toolbarController;
  late AnimationController _saveIndicatorController;

  Timer? _autoSaveTimer;
  NoteModel? _currentNote;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _showToolbar = false;

  // Formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();

    _currentNote = widget.note;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();

    _toolbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _saveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Show toolbar when content is focused
    _contentFocus.addListener(() {
      if (_contentFocus.hasFocus) {
        _toolbarController.forward();
        setState(() => _showToolbar = true);
      } else {
        _toolbarController.reverse();
        setState(() => _showToolbar = false);
      }
    });

    // Watch for changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    // Auto-focus title for new notes
    if (widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _toolbarController.dispose();
    _saveIndicatorController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _hasChanges = true);
    // Debounce auto-save: 1.5 seconds after last keystroke
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_hasChanges) return;
    await _save(showIndicator: true);
  }

  Future<void> _save({bool showIndicator = false}) async {
    if (!mounted) return;

    final title = _titleController.text;
    final content = _contentController.text;

    // Don't save completely empty notes
    if (title.isEmpty && content.isEmpty && _currentNote == null) return;

    setState(() => _isSaving = true);

    NoteModel note;
    if (_currentNote != null) {
      note = _currentNote!.copyWith(title: title, content: content);
    } else {
      note = NoteModel(title: title, content: content);
    }

    await ref.read(notesProvider.notifier).saveNote(note);
    _currentNote = note;

    setState(() {
      _hasChanges = false;
      _isSaving = false;
    });

    if (showIndicator) {
      _saveIndicatorController
          .forward()
          .then((_) => _saveIndicatorController.reverse());
    }
  }

  Future<void> _attachFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    await _addAttachment(
      name: file.name,
      sourcePath: file.path!,
      type: _getFileType(file.extension ?? ''),
      sizeBytes: file.size,
    );
  }

  Future<void> _attachImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final XFile? image = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);

    if (image == null) return;

    final file = File(image.path);
    final size = await file.length();

    await _addAttachment(
      name: p.basename(image.path),
      sourcePath: image.path,
      type: 'image',
      sizeBytes: size,
    );

    // Insert image tag in content
    final cursor = _contentController.selection.baseOffset;
    final text = _contentController.text;
    final insertPos = cursor < 0 ? text.length : cursor;
    final newText =
        '${text.substring(0, insertPos)}\n[Image: ${p.basename(image.path)}]\n${text.substring(insertPos)}';
    _contentController.text = newText;
  }

  Future<void> _addAttachment({
    required String name,
    required String sourcePath,
    required String type,
    required int sizeBytes,
  }) async {
    try {
      // Copy file to app documents directory for persistence
      final docsDir = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${docsDir.path}/attachments');
      if (!await attachDir.exists()) await attachDir.create(recursive: true);

      final destPath = '${attachDir.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
      await File(sourcePath).copy(destPath);

      final attachment = NoteAttachment(
        name: name,
        path: destPath,
        type: type,
        sizeBytes: sizeBytes,
      );

      // Ensure note exists first
      if (_currentNote == null) await _save();

      final updatedNote = _currentNote!.copyWith(
        attachments: [...(_currentNote?.attachments ?? []), attachment],
      );
      await ref.read(notesProvider.notifier).saveNote(updatedNote);
      _currentNote = updatedNote;

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attached: $name'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'doc';
      default:
        return 'txt';
    }
  }

  Future<void> _removeAttachment(String attachmentId) async {
    if (_currentNote == null) return;
    final updated = _currentNote!.copyWith(
      attachments: _currentNote!.attachments
          .where((a) => a.id != attachmentId)
          .toList(),
    );
    await ref.read(notesProvider.notifier).saveNote(updated);
    _currentNote = updated;
    setState(() {});
  }

  Future<void> _handleBack() async {
    _autoSaveTimer?.cancel();
    await _save();
    if (mounted) Navigator.of(context).pop();
  }

  void _applyFormatting(String format) {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = _contentController.text;
    final selectedText = text.substring(selection.start, selection.end);

    String formatted;
    switch (format) {
      case 'bold':
        formatted = '**$selectedText**';
        setState(() => _isBold = !_isBold);
        break;
      case 'italic':
        formatted = '_${selectedText}_';
        setState(() => _isItalic = !_isItalic);
        break;
      case 'underline':
        formatted = '__${selectedText}__';
        setState(() => _isUnderline = !_isUnderline);
        break;
      case 'bullet':
        final lines = selectedText.split('\n');
        formatted = lines.map((l) => '• $l').join('\n');
        break;
      case 'numbered':
        final lines = selectedText.split('\n');
        formatted =
            lines.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
        break;
      default:
        return;
    }

    final newText = text.replaceRange(selection.start, selection.end, formatted);
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + formatted.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noteColor =
        getNoteColor(_currentNote?.color ?? NoteColor.none, isDark);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: noteColor,
        appBar: AppBar(
          backgroundColor: noteColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          actions: [
            // Auto-save indicator
            AnimatedBuilder(
              animation: _saveIndicatorController,
              builder: (_, __) => FadeTransition(
                opacity: _saveIndicatorController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // Pin toggle
            IconButton(
              icon: Icon(
                (_currentNote?.isPinned ?? false)
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: (_currentNote?.isPinned ?? false)
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: () async {
                if (_currentNote == null) await _save();
                if (_currentNote != null) {
                  await ref
                      .read(notesProvider.notifier)
                      .togglePin(_currentNote!.id);
                  _currentNote = ref
                      .read(notesProvider)
                      .firstWhere((n) => n.id == _currentNote!.id,
                          orElse: () => _currentNote!);
                  setState(() {});
                }
              },
              tooltip: 'Pin note',
            ),

            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) async {
                if (_currentNote == null) await _save();
                switch (v) {
                  case 'color':
                    _showColorPicker();
                    break;
                  case 'tag':
                    _showTagDialog();
                    break;
                  case 'export_txt':
                    if (_currentNote != null) {
                      await ExportService.exportAsTxt(_currentNote!);
                    }
                    break;
                  case 'export_pdf':
                    if (_currentNote != null) {
                      await ExportService.exportAsPdf(_currentNote!);
                    }
                    break;
                  case 'delete':
                    if (_currentNote != null) {
                      await ref
                          .read(notesProvider.notifier)
                          .trashNote(_currentNote!.id);
                      if (mounted) Navigator.of(context).pop();
                    }
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Change color'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'tag',
                  child: Row(
                    children: [
                      Icon(Icons.label_outline_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Add tag'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'export_txt',
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Export as TXT'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
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
        body: Column(
          children: [
            // ─── Main Editor Area ────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Title',
                              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            onSubmitted: (_) => _contentFocus.requestFocus(),
                          ),

                          // Metadata row
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentNote != null
                                      ? DateFormat('MMM d, yyyy  h:mm a')
                                          .format(_currentNote!.updatedAt)
                                      : DateFormat('MMM d, yyyy  h:mm a')
                                          .format(DateTime.now()),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                                if (_currentNote != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_currentNote!.wordCount} words',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Tags row
                          if (_currentNote != null &&
                              _currentNote!.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _currentNote!.tags.map((tag) {
                                  return GestureDetector(
                                    onTap: () => _removeTagDialog(tag),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style:
                                            theme.textTheme.labelMedium
                                                ?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Divider
                          Divider(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),

                          // Content field
                          TextField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start writing...',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                                height: 1.7,
                              ),
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            minLines: 10,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Attachments ──────────────────────────────────────
                  if (_currentNote != null &&
                      _currentNote!.attachments.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _AttachmentsList(
                        attachments: _currentNote!.attachments,
                        onRemove: _removeAttachment,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // ─── Formatting Toolbar ──────────────────────────────────────
            AnimatedBuilder(
              animation: _toolbarController,
              builder: (_, child) => SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: _toolbarController,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              ),
              child: _FormattingToolbar(
                isBold: _isBold,
                isItalic: _isItalic,
                isUnderline: _isUnderline,
                onFormat: _applyFormatting,
                onAttachFile: _attachFile,
                onAttachImage: () => _attachImage(),
                onAttachCamera: () => _attachImage(fromCamera: true),
                noteColor: noteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ColorPickerSheet(
        currentColor: _currentNote?.color ?? NoteColor.none,
        onSelect: (color) async {
          if (_currentNote == null) await _save();
          if (_currentNote != null) {
            await ref
                .read(notesProvider.notifier)
                .updateColor(_currentNote!.id, color);
            _currentNote = ref.read(notesProvider).firstWhere(
                  (n) => n.id == _currentNote!.id,
                  orElse: () => _currentNote!,
                );
            setState(() {});
          }
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            prefixText: '#',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) async {
            final tag = controller.text.trim().toLowerCase();
            if (tag.isNotEmpty && _currentNote != null) {
              await ref.read(notesProvider.notifier).addTag(_currentNote!.id, tag);
              _currentNote = ref.read(notesProvider).firstWhere(
                    (n) => n.id == _currentNote!.id,
                    orElse: () => _currentNote!,
                  );
              setState(() {});
            }
            if (mounted) Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final tag = controller.text.trim().toLowerCase();
              if (tag.isNotEmpty && _currentNote != null) {
                await ref
                    .read(notesProvider.notifier)
                    .addTag(_currentNote!.id, tag);
                _currentNote = ref.read(notesProvider).firstWhere(
                      (n) => n.id == _currentNote!.id,
                      orElse: () => _currentNote!,
                    );
                setState(() {});
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTagDialog(String tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Tag'),
        content: Text('Remove "#$tag" from this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_currentNote != null) {
                await ref
                    .read(notesProvider.notifier)
                    .removeTag(_currentNote!.id, tag);
                _currentNote = ref.read(notesProvider).firstWhere(
                      (n) => n.id == _currentNote!.id,
                      orElse: () => _currentNote!,
                    );
                setState(() {});
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _FormattingToolbar extends StatelessWidget {
  final bool isBold, isItalic, isUnderline;
  final ValueChanged<String> onFormat;
  final VoidCallback onAttachFile;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachCamera;
  final Color noteColor;

  const _FormattingToolbar({
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.onFormat,
    required this.onAttachFile,
    required this.onAttachImage,
    required this.onAttachCamera,
    required this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _FormatButton(
              icon: Icons.format_bold_rounded,
              isActive: isBold,
              onTap: () => onFormat('bold'),
              tooltip: 'Bold',
            ),
            _FormatButton(
              icon: Icons.format_italic_rounded,
              isActive: isItalic,
              onTap: () => onFormat('italic'),
              tooltip: 'Italic',
            ),
            _FormatButton(
              icon: Icons.format_underline_rounded,
              isActive: isUnderline,
              onTap: () => onFormat('underline'),
              tooltip: 'Underline',
            ),
            _FormatButton(
              icon: Icons.format_list_bulleted_rounded,
              onTap: () => onFormat('bullet'),
              tooltip: 'Bullet list',
            ),
            _FormatButton(
              icon: Icons.format_list_numbered_rounded,
              onTap: () => onFormat('numbered'),
              tooltip: 'Numbered list',
            ),
            const VerticalDivider(indent: 10, endIndent: 10),
            _FormatButton(
              icon: Icons.attach_file_rounded,
              onTap: onAttachFile,
              tooltip: 'Attach file',
            ),
            _FormatButton(
              icon: Icons.image_outlined,
              onTap: onAttachImage,
              tooltip: 'Add image',
            ),
            _FormatButton(
              icon: Icons.camera_alt_outlined,
              onTap: onAttachCamera,
              tooltip: 'Camera',
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _FormatButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: isActive
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _AttachmentsList extends StatelessWidget {
  final List<NoteAttachment> attachments;
  final ValueChanged<String> onRemove;

  const _AttachmentsList({
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = attachments.where((a) => a.type == 'image').toList();
    final files =
        attachments.where((a) => a.type != 'image').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image grid
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Images',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: images.length,
                  itemBuilder: (_, i) {
                    final img = images[i];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(img.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemove(img.id),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

        // File list
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Files',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...files.map((f) => _FileListItem(
                      attachment: f,
                      onRemove: () => onRemove(f.id),
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _FileListItem extends StatelessWidget {
  final NoteAttachment attachment;
  final VoidCallback onRemove;

  const _FileListItem({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color iconColor;
    switch (attachment.type) {
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
        iconColor = Colors.red;
        break;
      case 'doc':
        icon = Icons.description_outlined;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.text_snippet_outlined;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatBytes(attachment.sizeBytes),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final NoteColor currentColor;
  final ValueChanged<NoteColor> onSelect;

  const _ColorPickerSheet({
    required this.currentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const colors = [
      (NoteColor.none, 'Default'),
      (NoteColor.yellow, 'Yellow'),
      (NoteColor.blue, 'Blue'),
      (NoteColor.green, 'Green'),
      (NoteColor.pink, 'Pink'),
      (NoteColor.purple, 'Purple'),
      (NoteColor.orange, 'Orange'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note Color', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((entry) {
              final (color, label) = entry;
              final bg = getNoteColor(color, isDark);
              final isSelected = currentColor == color;

              return GestureDetector(
                onTap: () => onSelect(color),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color == NoteColor.none
                            ? theme.colorScheme.surfaceVariant
                            : bg,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2.5,
                              )
                            : Border.all(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(label, style: theme.textTheme.labelSmall),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }
}
