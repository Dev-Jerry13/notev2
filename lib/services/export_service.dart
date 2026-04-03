// lib/services/export_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';

/// Handles exporting notes as .txt or .pdf
class ExportService {
  /// Export note as plain text file
  static Future<void> exportAsTxt(NoteModel note) async {
    try {
      final dir = await getTemporaryDirectory();
      final safeName = note.title.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final fileName = '${safeName.isEmpty ? 'note' : safeName}.txt';
      final file = File('${dir.path}/$fileName');

      final buffer = StringBuffer();
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      buffer.writeln();
      buffer.writeln(note.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln(
          'Created: ${DateFormat('MMM d, yyyy HH:mm').format(note.createdAt)}');
      buffer.writeln(
          'Updated: ${DateFormat('MMM d, yyyy HH:mm').format(note.updatedAt)}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('Tags: ${note.tags.join(', ')}');
      }

      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: note.title);
    } catch (e) {
      rethrow;
    }
  }

  /// Export note as PDF
  static Future<void> exportAsPdf(NoteModel note) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Title
            pw.Text(
              note.title.isEmpty ? 'Untitled Note' : note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Timestamps
            pw.Text(
              'Created: ${DateFormat('MMM d, yyyy').format(note.createdAt)}  •  '
              'Updated: ${DateFormat('MMM d, yyyy').format(note.updatedAt)}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),

            // Tags
            if (note.tags.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Tags: ${note.tags.join(' • ')}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue600,
                ),
              ),
            ],

            pw.Divider(height: 24, color: PdfColors.grey300),

            // Content
            pw.Text(
              note.content.isEmpty ? 'No content' : note.content,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 6,
              ),
            ),

            // Attachments list
            if (note.attachments.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text(
                'Attachments (${note.attachments.length})',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...note.attachments.map(
                (a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '• ${a.name} (${_formatBytes(a.sizeBytes)})',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final safeName = note.title.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final fileName = '${safeName.isEmpty ? 'note' : safeName}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: note.title);
    } catch (e) {
      rethrow;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
