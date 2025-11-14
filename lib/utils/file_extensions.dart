import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// File icon extension
///
/// Replaces getFileIcon method - reduces coupling
extension FileIconExtension on String {
  IconData get fileIcon {
    final ext = path.extension(this).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.txt':
        return Icons.text_snippet;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}

/// File kind extension
///
/// Replaces getFileKind method
extension FileKindExtension on String {
  String get fileKind {
    final ext = path.extension(this).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'PDF Document';
      case '.doc':
      case '.docx':
        return 'Microsoft Document';
      case '.xls':
      case '.xlsx':
        return 'Microsoft Spreadsheet';
      case '.txt':
        return 'TXT Document';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return 'Image';
      case '.zip':
        return 'ZIP Archive';
      case '.rar':
        return 'RAR Archive';
      case '.7z':
        return '7-Zip Archive';
      default:
        return 'Document';
    }
  }
}

/// File color extension
///
/// Replaces getFileColor method
extension FileColorExtension on String {
  Color get fileColor {
    final ext = path.extension(this).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Colors.red.shade600;
      case '.doc':
      case '.docx':
        return Colors.blue.shade700;
      case '.xls':
      case '.xlsx':
        return Colors.green.shade700;
      case '.txt':
        return Colors.grey.shade700;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Colors.purple.shade600;
      case '.zip':
      case '.rar':
      case '.7z':
        return const Color(0xFFF6A00C);
      default:
        return Colors.blue.shade600;
    }
  }
}
