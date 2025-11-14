import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:winzipper/common/constants.dart';
import 'package:winzipper/data/service/archive_service.dart';
import 'package:winzipper/feature/home/models/archive_callbacks.dart';
import 'package:winzipper/feature/home/models/archive_view_state.dart';
import 'package:winzipper/feature/home/models/downloads_callbacks.dart';
import 'package:winzipper/feature/home/models/downloads_view_state.dart';
import 'package:winzipper/feature/home/view/widgets/archive_picker_section.dart';
import 'package:winzipper/feature/home/view/widgets/downloads_browser_section.dart';
import 'package:winzipper/services/dialog_service.dart';
import 'package:winzipper/utils/file_extensions.dart';
import 'package:winzipper/utils/system_tools_checker.dart';
import 'package:winzipper/widgets/cloud_upload_dialog.dart';

/// Home Screen - Archive Management
///
/// Responsibilities:
/// - Coordinate archive and downloads state
/// - Handle archive operations (extract, compress)
/// - Delegate UI to child widgets
/// - Delegate dialogs to DialogService
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Archive state
  String? _selectedFilePath;
  List<String> _archiveContents = [];
  List<String> _allArchiveContents = [];
  ArchiveType _currentArchiveType = ArchiveType.unknown;
  String _currentPath = '';

  // UI state
  bool _isLoading = false;
  String _statusMessage = '';
  int? _hoveredIndex;
  int? _selectedIndex;

  // Downloads state
  List<FileSystemEntity> _downloadsContents = [];
  int? _downloadsHoveredIndex;
  int? _downloadsSelectedIndex;
  String _currentDownloadsPath = '';

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Sort state
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadsFolder();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Safe setState with mounted check
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // ========================================
  // DOWNLOADS FOLDER OPERATIONS
  // ========================================

  Future<void> _loadDownloadsFolder({String? subPath}) async {
    try {
      final basePath = '${Platform.environment['HOME']}/Downloads';
      final fullPath =
          subPath == null || subPath.isEmpty ? basePath : '$basePath/$subPath';
      final dir = Directory(fullPath);

      if (await dir.exists()) {
        final contents = await dir.list().toList();
        _safeSetState(() {
          _currentDownloadsPath = subPath ?? '';
          _downloadsContents = contents;
          _sortDownloadsContents();
        });
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(
          context,
          'Access Error',
          'Cannot access downloads folder: $e',
        );
      }
    }
  }

  void _navigateToDownloadsFolder(String folderName) {
    final newPath = _currentDownloadsPath.isEmpty
        ? folderName
        : '$_currentDownloadsPath/$folderName';
    _loadDownloadsFolder(subPath: newPath);
  }

  void _navigateBackInDownloads() {
    if (_currentDownloadsPath.isEmpty) return;

    final parts = _currentDownloadsPath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty ? '' : parts.join('/');
    _loadDownloadsFolder(subPath: newPath.isEmpty ? null : newPath);
  }

  void _sortDownloadsContents() {
    _downloadsContents.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'name':
          compare = path
              .basename(a.path)
              .toLowerCase()
              .compareTo(path.basename(b.path).toLowerCase());
        case 'date':
          final aStat = a.statSync();
          final bStat = b.statSync();
          compare = aStat.modified.compareTo(bStat.modified);
        case 'kind':
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir == bIsDir) {
            compare = 0;
          } else {
            compare = aIsDir ? -1 : 1;
          }
        case 'size':
          final aSize = a is File ? a.lengthSync() : 0;
          final bSize = b is File ? b.lengthSync() : 0;
          compare = aSize.compareTo(bSize);
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  // ========================================
  // ARCHIVE OPERATIONS
  // ========================================

  Future<void> _pickArchiveFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'],
      );

      if (result != null && result.files.single.path != null) {
        await _openArchiveFromPath(result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(context, 'Error', 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _openArchiveFromPath(String filePath) async {
    if (_isLoading) return;

    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();

      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        DialogService.showError(
          context,
          'Archive Too Large',
          'Archive size: ${AppConstants.formatBytes(fileSize)}\n'
              'Maximum: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}',
        );
        return;
      }

      _safeSetState(() {
        _selectedFilePath = filePath;
        _isLoading = true;
        _statusMessage = 'Loading archive contents...';
        _currentArchiveType = ArchiveService().detectArchiveType(filePath);
      });

      final service = ArchiveService();
      final contents = await service.listArchiveContents(filePath);

      _safeSetState(() {
        _allArchiveContents = contents;
        _archiveContents = contents;
        _isLoading = false;
        _statusMessage = contents.isEmpty
            ? 'Archive is empty'
            : '${contents.length} ${contents.length == 1 ? 'item' : 'items'}';
      });
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        DialogService.showError(context, 'Error', 'Failed to load archive: $e');
      }
    }
  }

  Future<void> _extractArchive() async {
    if (_selectedFilePath == null || _isLoading) return;

    try {
      final file = File(_selectedFilePath!);

      if (!await file.exists()) {
        throw Exception('Archive file no longer exists');
      }

      final fileSize = await file.length();

      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        DialogService.showError(
          context,
          'Archive Too Large',
          'Archive size: ${AppConstants.formatBytes(fileSize)}\n'
              'Maximum: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}',
        );
        return;
      }

      String? requiredTool;
      if (_currentArchiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolUnrar;
      } else if (_currentArchiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable =
            await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          DialogService.showError(
            context,
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      final availableSpace =
          await SystemToolsChecker.getAvailableDiskSpace(result);
      final estimatedNeeded = fileSize * AppConstants.diskSpaceMultiplier;

      if (availableSpace < estimatedNeeded) {
        DialogService.showError(
          context,
          'Insufficient Disk Space',
          'Required: ~${AppConstants.formatBytes(estimatedNeeded)}\n'
              'Available: ${AppConstants.formatBytes(availableSpace)}',
        );
        return;
      }

      _safeSetState(() {
        _isLoading = true;
        _statusMessage = 'Extracting archive...';
      });

      final service = ArchiveService();
      final success = await service.extractArchive(_selectedFilePath!, result);

      _safeSetState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Archive extracted successfully!'
            : 'Failed to extract archive';
      });

      if (mounted) {
        if (success) {
          DialogService.showSuccess(
            context,
            'Extraction Complete',
            'Archive extracted to:\n$result',
            filePath: _selectedFilePath,
            onCloudUpload: () {
              if (_selectedFilePath != null) {
                CloudUploadDialog.show(context, _selectedFilePath!);
              }
            },
          );
        } else {
          var errorMessage = 'Could not extract the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          DialogService.showError(context, 'Extraction Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        DialogService.showError(
          context,
          'Error',
          'An unexpected error occurred:\n$e',
        );
      }
    }
  }

  Future<void> _compressFiles() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final sourcePaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .toList();

      if (sourcePaths.isEmpty) return;

      var totalSourceSize = 0;
      for (final sourcePath in sourcePaths) {
        try {
          final file = File(sourcePath);
          if (await file.exists()) {
            totalSourceSize += await file.length();
          }
        } catch (e) {
          // Continue
        }
      }

      if (totalSourceSize > AppConstants.maxArchiveSizeBytes * 2) {
        DialogService.showError(
          context,
          'Files Too Large',
          'Total size: ${AppConstants.formatBytes(totalSourceSize)}\n'
              'Maximum: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes * 2)}',
        );
        return;
      }

      final archiveName = await DialogService.showArchiveName(context);
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult == null) return;

      final destinationDir = File(saveResult).parent.path;
      final availableSpace =
          await SystemToolsChecker.getAvailableDiskSpace(destinationDir);
      final estimatedNeeded = (totalSourceSize * 1.1).toInt();

      if (availableSpace < estimatedNeeded) {
        DialogService.showError(
          context,
          'Insufficient Disk Space',
          'Required: ~${AppConstants.formatBytes(estimatedNeeded)}\n'
              'Available: ${AppConstants.formatBytes(availableSpace)}',
        );
        return;
      }

      final archiveType = ArchiveService().detectArchiveType(saveResult);
      String? requiredTool;
      if (archiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolRar;
      } else if (archiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable =
            await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          DialogService.showError(
            context,
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      _safeSetState(() {
        _isLoading = true;
        _statusMessage =
            'Compressing ${sourcePaths.length} ${sourcePaths.length == 1 ? 'file' : 'files'}...';
      });

      final service = ArchiveService();
      final success = await service.compressToArchive(sourcePaths, saveResult);

      _safeSetState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Files compressed successfully!'
            : 'Failed to compress files';
      });

      if (mounted) {
        if (success) {
          DialogService.showSuccess(
            context,
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
            onCloudUpload: () => CloudUploadDialog.show(context, saveResult),
          );
        } else {
          var errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          DialogService.showError(context, 'Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        DialogService.showError(
          context,
          'Error',
          'An unexpected error occurred:\n$e',
        );
      }
    }
  }

  Future<void> _compressDirectory() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      var directorySize = 0;
      try {
        final dir = Directory(result);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              try {
                directorySize += await entity.length();
              } catch (e) {
                // Continue
              }
            }
          }
        }
      } catch (e) {
        // Continue
      }

      if (directorySize > AppConstants.maxArchiveSizeBytes * 2) {
        DialogService.showError(
          context,
          'Directory Too Large',
          'Directory size: ${AppConstants.formatBytes(directorySize)}\n'
              'Maximum: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes * 2)}',
        );
        return;
      }

      final archiveName = await DialogService.showArchiveName(context);
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult == null) return;

      final destinationDir = File(saveResult).parent.path;
      final availableSpace =
          await SystemToolsChecker.getAvailableDiskSpace(destinationDir);
      final estimatedNeeded = (directorySize * 1.1).toInt();

      if (availableSpace < estimatedNeeded) {
        DialogService.showError(
          context,
          'Insufficient Disk Space',
          'Required: ~${AppConstants.formatBytes(estimatedNeeded)}\n'
              'Available: ${AppConstants.formatBytes(availableSpace)}',
        );
        return;
      }

      final archiveType = ArchiveService().detectArchiveType(saveResult);
      String? requiredTool;
      if (archiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolRar;
      } else if (archiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable =
            await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          DialogService.showError(
            context,
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      _safeSetState(() {
        _isLoading = true;
        _statusMessage = 'Compressing directory...';
      });

      final service = ArchiveService();
      final success = await service.compressToArchive([result], saveResult);

      _safeSetState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Directory compressed successfully!'
            : 'Failed to compress directory';
      });

      if (mounted) {
        if (success) {
          DialogService.showSuccess(
            context,
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
            onCloudUpload: () => CloudUploadDialog.show(context, saveResult),
          );
        } else {
          var errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          DialogService.showError(context, 'Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        DialogService.showError(
          context,
          'Error',
          'An unexpected error occurred:\n$e',
        );
      }
    }
  }

  // ========================================
  // ARCHIVE NAVIGATION
  // ========================================

  List<String> _getItemsInCurrentPath(String basePath) {
    final items = <String>{};
    final prefix = basePath.isEmpty ? '' : '$basePath/';

    for (final item in _allArchiveContents) {
      if (item.startsWith(prefix)) {
        final relativePath = item.substring(prefix.length);
        if (relativePath.isEmpty) continue;

        final parts = relativePath.split('/');
        if (parts.length == 1 || (parts.length == 2 && parts[1].isEmpty)) {
          items.add(item);
        } else {
          final folderName = parts[0];
          items.add('$prefix$folderName/');
        }
      }
    }

    return items.toList()..sort();
  }

  void _navigateToFolder(String folderPath) {
    _safeSetState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchQuery = '';
        _searchController.clear();
      }
      _currentPath = folderPath;
      _archiveContents = _getItemsInCurrentPath(folderPath);
      _selectedIndex = null;
    });
  }

  void _navigateBack() {
    if (_currentPath.isEmpty) return;

    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty ? '' : parts.join('/');

    _navigateToFolder(newPath);
  }

  void _clearSelection() {
    _safeSetState(() {
      _selectedFilePath = null;
      _archiveContents = [];
      _allArchiveContents = [];
      _statusMessage = '';
      _currentArchiveType = ArchiveType.unknown;
      _currentPath = '';
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // ========================================
  // FILE OPERATIONS
  // ========================================

  Future<void> _viewSelectedFile() async {
    if (_selectedIndex == null || _selectedIndex! >= _archiveContents.length) {
      return;
    }

    final selectedItem = _archiveContents[_selectedIndex!];
    if (selectedItem.endsWith('/')) {
      _navigateToFolder(selectedItem.substring(0, selectedItem.length - 1));
      return;
    }

    final ext = path.extension(selectedItem).toLowerCase();
    final isTextFile =
        ['.txt', '.md', '.json', '.xml', '.csv', '.log'].contains(ext);

    if (!isTextFile) {
      DialogService.showError(
        context,
        'Preview Not Supported',
        'File preview is only available for text files.\n\nTo view other files, extract the archive first.',
      );
      return;
    }

    try {
      _safeSetState(() {
        _isLoading = true;
        _statusMessage = 'Loading file preview...';
      });

      final tempDir = Directory.systemTemp.createTempSync('winzipper_view_');
      final service = ArchiveService();
      final success = await service.extractSpecificFile(
        _selectedFilePath!,
        selectedItem,
        tempDir.path,
      );

      if (!success) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Preview Failed',
          'Could not extract file for preview.',
        );
        return;
      }

      final fileName = path.basename(selectedItem);
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Preview Failed',
          'Extracted file not found.',
        );
        return;
      }

      final fileSize = await file.length();
      const maxPreviewSize = 10 * 1024 * 1024;

      if (fileSize > maxPreviewSize) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'File Too Large for Preview',
          'File size: ${AppConstants.formatBytes(fileSize)}\n'
              'Maximum for preview: ${AppConstants.formatBytes(maxPreviewSize)}\n\n'
              'Please extract the archive to view this file.',
        );
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          // Ignore
        }
        return;
      }

      final content = await file.readAsString();
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore
      }

      _safeSetState(() => _isLoading = false);
      if (mounted) {
        DialogService.showFilePreview(context, fileName, content);
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        DialogService.showError(
          context,
          'Preview Error',
          'An error occurred:\n$e',
        );
      }
    }
  }

  void _showFileInfo() {
    if (_selectedIndex == null || _selectedIndex! >= _archiveContents.length) {
      return;
    }

    final selectedItem = _archiveContents[_selectedIndex!];
    final fileName = path.basename(selectedItem);
    final isFolder = selectedItem.endsWith('/');
    final ext = path.extension(selectedItem);

    DialogService.showFileInfo(
      context,
      fileName,
      isFolder ? 'Folder' : fileName.fileKind,
      ext,
      selectedItem,
      path.basename(_selectedFilePath!),
      isFolder,
    );
  }

  Future<void> _previewNestedArchive(String archiveItemPath) async {
    try {
      final tempDir = Directory.systemTemp.createTempSync('winzipper_preview_');

      _safeSetState(() {
        _isLoading = true;
        _statusMessage = 'Extracting nested archive...';
      });

      final service = ArchiveService();
      final success = await service.extractSpecificFile(
        _selectedFilePath!,
        archiveItemPath,
        tempDir.path,
      );

      if (!success) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Preview Failed',
          'Could not extract the nested archive for preview.',
        );
        return;
      }

      final extractedFileName = path.basename(archiveItemPath);
      final extractedFilePath = path.join(tempDir.path, extractedFileName);
      final extractedFile = File(extractedFilePath);

      if (!await extractedFile.exists()) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Preview Failed',
          'The extracted archive file was not found.',
        );
        return;
      }

      final nestedArchiveSize = await extractedFile.length();
      const maxNestedArchiveSize = 500 * 1024 * 1024;

      if (nestedArchiveSize > maxNestedArchiveSize) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Nested Archive Too Large',
          'Nested archive size: ${AppConstants.formatBytes(nestedArchiveSize)}\n'
              'Maximum for preview: ${AppConstants.formatBytes(maxNestedArchiveSize)}\n\n'
              'Please extract the main archive first to access this nested archive.',
        );
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          // Ignore
        }
        return;
      }

      final nestedContents =
          await service.listArchiveContents(extractedFilePath);

      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore
      }

      if (nestedContents.isEmpty) {
        _safeSetState(() => _isLoading = false);
        DialogService.showError(
          context,
          'Preview',
          'The nested archive "$extractedFileName" is empty.',
        );
        return;
      }

      _safeSetState(() => _isLoading = false);
      if (mounted) {
        DialogService.showNestedArchivePreview(
          context,
          extractedFileName,
          nestedContents,
        );
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        DialogService.showError(
          context,
          'Preview Error',
          'An error occurred:\n$e',
        );
      }
    }
  }

  // ========================================
  // BUILD METHOD
  // ========================================

  @override
  Widget build(BuildContext context) {
    // Create state objects
    final archiveState = ArchiveViewState(
      selectedFilePath: _selectedFilePath,
      archiveContents: _archiveContents,
      allArchiveContents: _allArchiveContents,
      isLoading: _isLoading,
      statusMessage: _statusMessage,
      currentArchiveType: _currentArchiveType,
      currentPath: _currentPath,
      isSearching: _isSearching,
      searchQuery: _searchQuery,
      selectedIndex: _selectedIndex,
      hoveredIndex: _hoveredIndex,
    );

    final archiveCallbacks = ArchiveCallbacks(
      onPickFile: _pickArchiveFile,
      onExtract: _extractArchive,
      onCompressFiles: _compressFiles,
      onCompressDirectory: _compressDirectory,
      onCloudUpload: () {
        if (_selectedFilePath != null) {
          CloudUploadDialog.show(context, _selectedFilePath!);
        }
      },
      onNavigateToFolder: _navigateToFolder,
      onNavigateBack: _navigateBack,
      onViewFile: _viewSelectedFile,
      onShowFileInfo: _showFileInfo,
      onPreviewNestedArchive: _previewNestedArchive,
      onSearchChanged: (query) => _safeSetState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _archiveContents = _getItemsInCurrentPath(_currentPath);
        } else {
          _archiveContents = _allArchiveContents
              .where(
                (item) => item.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        }
      }),
      onSearchToggle: (searching) =>
          _safeSetState(() => _isSearching = searching),
      onHoverChanged: (index) => _safeSetState(() => _hoveredIndex = index),
      onSelectChanged: (index) => _safeSetState(() => _selectedIndex = index),
    );

    final downloadsState = DownloadsViewState(
      contents: _downloadsContents,
      currentPath: _currentDownloadsPath,
      hoveredIndex: _downloadsHoveredIndex,
      selectedIndex: _downloadsSelectedIndex,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );

    final downloadsCallbacks = DownloadsCallbacks(
      onNavigateToFolder: _navigateToDownloadsFolder,
      onNavigateBack: _navigateBackInDownloads,
      onOpenArchive: _openArchiveFromPath,
      onHoverChanged: (index) =>
          _safeSetState(() => _downloadsHoveredIndex = index),
      onSelectChanged: (index) =>
          _safeSetState(() => _downloadsSelectedIndex = index),
      onSortChanged: (sortBy, ascending) => _safeSetState(() {
        _sortBy = sortBy;
        _sortAscending = ascending;
        _sortDownloadsContents();
      }),
    );

    return Row(
      children: [
        // Downloads browser (left side) - 2 parameters instead of 16
        DownloadsBrowserSection(
          state: downloadsState,
          callbacks: downloadsCallbacks,
        ),

        const VerticalDivider(width: 1),

        // Archive content area (right side) - 3 parameters instead of 28
        Expanded(
          child: ArchivePickerSection(
            state: archiveState,
            callbacks: archiveCallbacks,
            searchController: _searchController,
          ),
        ),
      ],
    );
  }
}
