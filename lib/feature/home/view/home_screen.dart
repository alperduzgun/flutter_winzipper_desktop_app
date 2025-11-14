part 'widgets/_archive_picker_section.dart';
part 'widgets/_downloads_browser_section.dart';
part 'widgets/_archive_toolbar.dart';
part 'widgets/_status_message.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../common/constants.dart';
import '../../../data/service/archive_service.dart';
import '../../../utils/system_tools_checker.dart';
import '../../../widgets/cloud_upload_dialog.dart';

/// Home Screen - Archive Management
///
/// Responsibilities:
/// - Archive file selection and preview
/// - Downloads folder browsing
/// - Archive operations (extract, compress)
/// - Cloud upload integration
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
  String _currentPath = '';

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

  /// Safe setState with mounted check (Chaos Engineering)
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
      final fullPath = subPath == null || subPath.isEmpty
          ? basePath
          : '$basePath/$subPath';
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
      // Silently fail for permissions/access issues
      if (mounted) {
        _showErrorDialog('Access Error', 'Cannot access downloads folder: $e');
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
          compare = path.basename(a.path)
              .toLowerCase()
              .compareTo(path.basename(b.path).toLowerCase());
          break;
        case 'date':
          final aStat = a.statSync();
          final bStat = b.statSync();
          compare = aStat.modified.compareTo(bStat.modified);
          break;
        case 'kind':
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir == bIsDir) {
            compare = 0;
          } else {
            compare = aIsDir ? -1 : 1;
          }
          break;
        case 'size':
          final aSize = a is File ? a.lengthSync() : 0;
          final bSize = b is File ? b.lengthSync() : 0;
          compare = aSize.compareTo(bSize);
          break;
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
        _showErrorDialog('Error', 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _openArchiveFromPath(String filePath) async {
    // Prevent concurrent operations
    if (_isLoading) return;

    try {
      final file = File(filePath);

      // Chaos Engineering: Check file exists
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();

      // Chaos Engineering: Check file size
      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        _showErrorDialog(
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
        _showErrorDialog('Error', 'Failed to load archive: $e');
      }
    }
  }

  Future<void> _extractArchive() async {
    if (_selectedFilePath == null || _isLoading) return;

    try {
      final file = File(_selectedFilePath!);

      // Chaos Engineering: Check file still exists
      if (!await file.exists()) {
        throw Exception('Archive file no longer exists');
      }

      final fileSize = await file.length();

      // Chaos Engineering: Check file size
      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        _showErrorDialog(
          'Archive Too Large',
          'Archive size: ${AppConstants.formatBytes(fileSize)}\n'
          'Maximum: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}',
        );
        return;
      }

      // Chaos Engineering: Check required tools
      String? requiredTool;
      if (_currentArchiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolUnrar;
      } else if (_currentArchiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable = await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          _showErrorDialog(
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      // Chaos Engineering: Check disk space
      final availableSpace = await SystemToolsChecker.getAvailableDiskSpace(result);
      final estimatedNeeded = fileSize * AppConstants.diskSpaceMultiplier;

      if (availableSpace < estimatedNeeded) {
        _showErrorDialog(
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
          _showSuccessDialog(
            'Extraction Complete',
            'Archive extracted to:\n$result',
            filePath: _selectedFilePath,
          );
        } else {
          String errorMessage = 'Could not extract the archive.';
          if (requiredTool != null) {
            errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Extraction Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        _showErrorDialog('Error', 'An unexpected error occurred:\n$e');
      }
    }
  }

  Future<void> _compressFiles() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final sourcePaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .toList();

      if (sourcePaths.isEmpty) return;

      final archiveName = await _showArchiveNameDialog();
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult == null) return;

      // Chaos Engineering: Check required tools
      final archiveType = ArchiveService().detectArchiveType(saveResult);
      String? requiredTool;
      if (archiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolRar;
      } else if (archiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable = await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          _showErrorDialog(
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      _safeSetState(() {
        _isLoading = true;
        _statusMessage = 'Compressing ${sourcePaths.length} ${sourcePaths.length == 1 ? 'file' : 'files'}...';
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
          _showSuccessDialog(
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
          );
        } else {
          String errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        _showErrorDialog('Error', 'An unexpected error occurred:\n$e');
      }
    }
  }

  Future<void> _compressDirectory() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      final archiveName = await _showArchiveNameDialog();
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult == null) return;

      // Chaos Engineering: Check required tools
      final archiveType = ArchiveService().detectArchiveType(saveResult);
      String? requiredTool;
      if (archiveType == ArchiveType.rar) {
        requiredTool = AppConstants.toolRar;
      } else if (archiveType == ArchiveType.sevenZip) {
        requiredTool = AppConstants.tool7zip;
      }

      if (requiredTool != null) {
        final isAvailable = await SystemToolsChecker.isToolAvailable(requiredTool);
        if (!isAvailable) {
          _showErrorDialog(
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
          _showSuccessDialog(
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
          );
        } else {
          String errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        _showErrorDialog('Error', 'An unexpected error occurred:\n$e');
      }
    }
  }

  Future<String?> _showArchiveNameDialog() async {
    if (!mounted) return null;

    String selectedFormat = '.zip';
    final controller = TextEditingController(text: 'archive');

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.archive, color: Color(0xFFF6A00C)),
              SizedBox(width: 12),
              Text('Create Archive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Archive Name:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter archive name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (value) => Navigator.pop(context, '$value$selectedFormat'),
                ),
                const SizedBox(height: 20),
                const Text('Format:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFormatChip('.zip', 'ZIP', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }, recommended: true),
                    _buildFormatChip('.tar.gz', 'TAR.GZ', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                    _buildFormatChip('.7z', '7-Zip', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                    _buildFormatChip('.tar', 'TAR', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedFormat == '.7z' ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedFormat == '.7z' ? Colors.orange.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedFormat == '.7z' ? Icons.info_outline : Icons.check_circle_outline,
                        size: 16,
                        color: selectedFormat == '.7z' ? Colors.orange.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFormatInfoMessage(selectedFormat),
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedFormat == '.7z' ? Colors.orange.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, '${controller.text}$selectedFormat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6A00C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Create Archive'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format, String label, String selectedFormat,
      Function(String) onSelect, {bool recommended = false}) {
    final isSelected = selectedFormat == format;
    return InkWell(
      onTap: () => onSelect(format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF6A00C)
              : recommended
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF6A00C)
                : recommended
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recommended && !isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 14, color: Colors.green.shade700),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : recommended
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatInfoMessage(String format) {
    switch (format) {
      case '.zip':
        return 'Best compatibility • Native support • No tools required';
      case '.tar.gz':
        return 'Great compression • Unix/Linux standard • Native support';
      case '.tar':
        return 'Uncompressed archive • Fast • Native support';
      case '.7z':
        return 'Best compression ratio • Requires 7z tool (brew install p7zip)';
      default:
        return 'Native support • No additional tools required';
    }
  }

  void _showSuccessDialog(String title, String message, {String? filePath}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          if (filePath != null) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                CloudUploadDialog.show(context, filePath);
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Share to Cloud'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF6A00C),
                side: const BorderSide(color: Color(0xFFF6A00C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A00C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  // ========================================
  // UI HELPERS
  // ========================================

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BUILD METHOD
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Downloads browser (left side)
        _DownloadsBrowserSection(
          contents: _downloadsContents,
          currentPath: _currentDownloadsPath,
          hoveredIndex: _downloadsHoveredIndex,
          selectedIndex: _downloadsSelectedIndex,
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          onNavigateToFolder: _navigateToDownloadsFolder,
          onNavigateBack: _navigateBackInDownloads,
          onOpenArchive: _openArchiveFromPath,
          onHoverChanged: (index) => _safeSetState(() => _downloadsHoveredIndex = index),
          onSelectChanged: (index) => _safeSetState(() => _downloadsSelectedIndex = index),
          onSortChanged: (sortBy, ascending) => _safeSetState(() {
            _sortBy = sortBy;
            _sortAscending = ascending;
            _sortDownloadsContents();
          }),
        ),

        const VerticalDivider(width: 1),

        // Archive content area (right side)
        Expanded(
          child: _ArchivePickerSection(
            selectedFilePath: _selectedFilePath,
            archiveContents: _archiveContents,
            isLoading: _isLoading,
            statusMessage: _statusMessage,
            currentArchiveType: _currentArchiveType,
            onPickFile: _pickArchiveFile,
            onExtract: _extractArchive,
            onCloudUpload: () {
              if (_selectedFilePath != null) {
                CloudUploadDialog.show(context, _selectedFilePath!);
              }
            },
          ),
        ),
      ],
    );
  }
}
