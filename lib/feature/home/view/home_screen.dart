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
  // HELPER METHODS
  // ========================================

  IconData _getFileIcon(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
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

  String _getFileKind(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
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

  Color _getFileColor(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getArchiveTypeLabel() {
    switch (_currentArchiveType) {
      case ArchiveType.zip:
        return 'ZIP Archive';
      case ArchiveType.rar:
        return 'RAR Archive';
      case ArchiveType.sevenZip:
        return '7-Zip Archive';
      case ArchiveType.tar:
        return 'TAR Archive';
      case ArchiveType.gzip:
        return 'GZIP Archive';
      case ArchiveType.bzip2:
        return 'BZIP2 Archive';
      default:
        return 'Archive';
    }
  }

  // ========================================
  // UI HELPERS
  // ========================================

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        ),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
    final isTextFile = ['.txt', '.md', '.json', '.xml', '.csv', '.log'].contains(ext);

    if (!isTextFile) {
      _showErrorDialog(
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
        _showErrorDialog('Preview Failed', 'Could not extract file for preview.');
        return;
      }

      final fileName = path.basename(selectedItem);
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        _safeSetState(() => _isLoading = false);
        _showErrorDialog('Preview Failed', 'Extracted file not found.');
        return;
      }

      final content = await file.readAsString();
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }

      _safeSetState(() => _isLoading = false);
      if (mounted) {
        _showFilePreviewDialog(fileName, content);
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('Preview Error', 'An error occurred:\n$e');
      }
    }
  }

  void _showFilePreviewDialog(String fileName, String content) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getFileIcon(fileName), color: _getFileColor(fileName), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFileInfo() {
    if (_selectedIndex == null || _selectedIndex! >= _archiveContents.length) {
      return;
    }

    final selectedItem = _archiveContents[_selectedIndex!];
    final fileName = path.basename(selectedItem);
    final isFolder = selectedItem.endsWith('/');
    final ext = path.extension(selectedItem);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6A00C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFolder ? Icons.folder : _getFileIcon(selectedItem),
                color: isFolder ? const Color(0xFFF6A00C) : _getFileColor(selectedItem),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('File Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Name', fileName),
              const Divider(),
              _buildInfoRow('Type', isFolder ? 'Folder' : _getFileKind(fileName)),
              if (!isFolder) ...[
                const Divider(),
                _buildInfoRow('Extension', ext.isEmpty ? 'None' : ext),
              ],
              const Divider(),
              _buildInfoRow('Path', selectedItem),
              const Divider(),
              _buildInfoRow('Archive', path.basename(_selectedFilePath!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
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
        _showErrorDialog('Preview Failed', 'Could not extract the nested archive for preview.');
        return;
      }

      final extractedFileName = path.basename(archiveItemPath);
      final extractedFilePath = path.join(tempDir.path, extractedFileName);
      final extractedFile = File(extractedFilePath);

      if (!await extractedFile.exists()) {
        _safeSetState(() => _isLoading = false);
        _showErrorDialog('Preview Failed', 'The extracted archive file was not found.');
        return;
      }

      final nestedContents = await service.listArchiveContents(extractedFilePath);

      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }

      if (nestedContents.isEmpty) {
        _safeSetState(() => _isLoading = false);
        _showErrorDialog('Preview', 'The nested archive "$extractedFileName" is empty.');
        return;
      }

      _safeSetState(() => _isLoading = false);
      if (mounted) {
        _showNestedArchivePreviewDialog(extractedFileName, nestedContents);
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('Preview Error', 'An error occurred:\n$e');
      }
    }
  }

  void _showNestedArchivePreviewDialog(String archiveName, List<String> contents) {
    if (!mounted) return;

    final folders = contents.where((item) => item.endsWith('/')).length;
    final files = contents.length - folders;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6A00C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.archive, color: Color(0xFFF6A00C), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(archiveName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text('$folders folders, $files files', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: ListView.builder(
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final item = contents[index];
              final itemName = path.basename(item);
              final isFolder = item.endsWith('/');
              return ListTile(
                leading: Icon(
                  isFolder ? Icons.folder : _getFileIcon(itemName),
                  size: 18,
                  color: isFolder ? const Color(0xFFF6A00C) : _getFileColor(itemName),
                ),
                title: Text(itemName, style: const TextStyle(fontSize: 13)),
                subtitle: Text(isFolder ? 'Folder' : _getFileKind(itemName), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          getFileIcon: _getFileIcon,
          getFileKind: _getFileKind,
          getFileColor: _getFileColor,
          getMonthName: _getMonthName,
        ),

        const VerticalDivider(width: 1),

        // Archive content area (right side)
        Expanded(
          child: _ArchivePickerSection(
            selectedFilePath: _selectedFilePath,
            archiveContents: _archiveContents,
            allArchiveContents: _allArchiveContents,
            isLoading: _isLoading,
            statusMessage: _statusMessage,
            currentArchiveType: _currentArchiveType,
            currentPath: _currentPath,
            isSearching: _isSearching,
            searchQuery: _searchQuery,
            searchController: _searchController,
            selectedIndex: _selectedIndex,
            hoveredIndex: _hoveredIndex,
            onPickFile: _pickArchiveFile,
            onExtract: _extractArchive,
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
                    .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
            }),
            onSearchToggle: (searching) => _safeSetState(() => _isSearching = searching),
            onHoverChanged: (index) => _safeSetState(() => _hoveredIndex = index),
            onSelectChanged: (index) => _safeSetState(() => _selectedIndex = index),
            getFileIcon: _getFileIcon,
            getFileKind: _getFileKind,
            getFileColor: _getFileColor,
            getArchiveTypeLabel: _getArchiveTypeLabel,
          ),
        ),
      ],
    );
  }
}
