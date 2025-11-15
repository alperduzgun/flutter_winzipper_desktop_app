import 'package:flutter/material.dart';

/// Archive view callbacks
///
/// Groups all callback functions to reduce parameter count
class ArchiveCallbacks {
  const ArchiveCallbacks({
    required this.onPickFile,
    required this.onExtract,
    required this.onCompressFiles,
    required this.onCompressDirectory,
    required this.onCloudUpload,
    required this.onNavigateToFolder,
    required this.onNavigateBack,
    required this.onViewFile,
    required this.onShowFileInfo,
    required this.onPreviewNestedArchive,
    required this.onHoverChanged,
    required this.onSelectChanged,
    required this.onDownloadsNavigateToFolder,
    required this.onDownloadsNavigateBack,
    required this.onDownloadsOpenArchive,
    required this.onDownloadsHoverChanged,
    required this.onDownloadsSelectChanged,
  });

  final VoidCallback onPickFile;
  final VoidCallback onExtract;
  final VoidCallback onCompressFiles;
  final VoidCallback onCompressDirectory;
  final VoidCallback onCloudUpload;
  final void Function(String) onNavigateToFolder;
  final VoidCallback onNavigateBack;
  final VoidCallback onViewFile;
  final VoidCallback onShowFileInfo;
  final void Function(String) onPreviewNestedArchive;
  final void Function(int?) onHoverChanged;
  final void Function(int?) onSelectChanged;
  final void Function(String) onDownloadsNavigateToFolder;
  final VoidCallback onDownloadsNavigateBack;
  final void Function(String) onDownloadsOpenArchive;
  final void Function(int?) onDownloadsHoverChanged;
  final void Function(int?) onDownloadsSelectChanged;
}
