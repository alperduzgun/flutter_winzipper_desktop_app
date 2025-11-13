import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../common/constants.dart';
import '../services/archive_service.dart';
import '../utils/system_tools_checker.dart';
import '../widgets/cloud_upload_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? _selectedFilePath;
  List<String> _archiveContents = [];
  List<String> _allArchiveContents = []; // Store all items for navigation
  bool _isLoading = false;
  String _statusMessage = '';
  ArchiveType _currentArchiveType = ArchiveType.unknown;
  int? _hoveredIndex;
  int? _selectedIndex;
  String _currentPath = ''; // Current folder path in archive
  bool _isSearching = false; // Search mode
  String _searchQuery = ''; // Current search query
  final TextEditingController _searchController = TextEditingController();
  List<FileSystemEntity> _downloadsContents = []; // Downloads folder contents
  int? _downloadsHoveredIndex;
  int? _downloadsSelectedIndex;
  String _sortBy = 'name'; // name, date, kind, size
  bool _sortAscending = true;
  String _currentDownloadsPath = ''; // Current folder path in Downloads (relative)

  // Public methods to be called from main.dart
  void pickArchiveFile() => _pickArchiveFile();
  void compressFiles() => _compressFiles();
  void compressDirectory() => _compressDirectory();

  @override
  void initState() {
    super.initState();
    _loadDownloadsFolder();
  }

  Future<void> _loadDownloadsFolder({String? subPath}) async {
    try {
      final basePath = '${Platform.environment['HOME']}/Downloads';
      final fullPath = subPath == null || subPath.isEmpty
          ? basePath
          : '$basePath/$subPath';
      final dir = Directory(fullPath);

      if (await dir.exists()) {
        final contents = await dir.list().toList();
        setState(() {
          _currentDownloadsPath = subPath ?? '';
          _downloadsContents = contents;
          _sortDownloadsContents();
        });
      }
    } catch (e) {
      // Ignore errors, keep empty list
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

  Future<void> _openArchiveFromPath(String filePath) async {
    try {
      // Check file size before loading
      final file = File(filePath);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        _showErrorDialog(
          'Archive Too Large',
          'Archive size: ${AppConstants.formatBytes(fileSize)}\nMaximum supported: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}\n\nCannot preview large archives.',
        );
        return;
      }

      setState(() {
        _selectedFilePath = filePath;
        _isLoading = true;
        _statusMessage = 'Loading archive contents...';
        _currentArchiveType = ArchiveService.detectArchiveType(filePath);
      });

      final contents = await ArchiveService.listArchiveContents(filePath);

      setState(() {
        _allArchiveContents = contents;
        _archiveContents = _getItemsInCurrentPath('');
        _currentPath = '';
        _isLoading = false;
        _statusMessage = contents.isEmpty
            ? 'Archive is empty or too large to preview'
            : '${contents.length} ${contents.length == 1 ? 'item' : 'items'} found';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showErrorDialog(
        'Error Opening Archive',
        'Could not open the archive:\n${e.toString()}',
      );
    }
  }

  void _sortDownloadsContents() {
    _downloadsContents.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;

      // Folders first
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;

      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = path.basename(a.path).toLowerCase().compareTo(
            path.basename(b.path).toLowerCase()
          );
          break;
        case 'date':
          final aStat = a.statSync();
          final bStat = b.statSync();
          comparison = aStat.modified.compareTo(bStat.modified);
          break;
        case 'kind':
          final aExt = path.extension(a.path).toLowerCase();
          final bExt = path.extension(b.path).toLowerCase();
          comparison = aExt.compareTo(bExt);
          break;
        case 'size':
          if (a is File && b is File) {
            try {
              comparison = a.lengthSync().compareTo(b.lengthSync());
            } catch (e) {
              comparison = 0;
            }
          }
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  Future<void> _pickArchiveFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Check file size before loading
        final file = File(filePath);
        final fileSize = await file.length();

        if (fileSize > AppConstants.maxArchiveSizeBytes) {
          _showErrorDialog(
            'Archive Too Large',
            'Archive size: ${AppConstants.formatBytes(fileSize)}\nMaximum supported: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}\n\nCannot preview large archives.',
          );
          return;
        }

        setState(() {
          _selectedFilePath = filePath;
          _isLoading = true;
          _statusMessage = 'Loading archive contents...';
          _currentArchiveType =
              ArchiveService.detectArchiveType(_selectedFilePath!);
        });

        final contents = await ArchiveService.listArchiveContents(
          _selectedFilePath!,
        );

        setState(() {
          _allArchiveContents = contents;
          _archiveContents = _getItemsInCurrentPath('');
          _currentPath = '';
          _isLoading = false;
          _statusMessage = contents.isEmpty
              ? 'Archive is empty or too large to preview'
              : '${contents.length} ${contents.length == 1 ? 'item' : 'items'} found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _extractArchive() async {
    if (_selectedFilePath == null) return;

    try {
      // Pre-flight checks
      final file = File(_selectedFilePath!);
      final fileSize = await file.length();

      // Check file size
      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        _showErrorDialog(
          'Archive Too Large',
          'Archive size: ${AppConstants.formatBytes(fileSize)}\nMaximum supported: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}\n\nLarge archives may cause memory issues.',
        );
        return;
      }

      // Check if required tools are available for this archive type
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
          _showErrorDialog(
            'Tool Not Found',
            SystemToolsChecker.getToolErrorMessage(requiredTool),
          );
          return;
        }
      }

      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        // Check disk space
        final availableSpace =
            await SystemToolsChecker.getAvailableDiskSpace(result);
        final estimatedNeeded = fileSize * AppConstants.diskSpaceMultiplier;

        if (availableSpace < estimatedNeeded) {
          _showErrorDialog(
            'Insufficient Disk Space',
            'Required: ~${AppConstants.formatBytes(estimatedNeeded)}\nAvailable: ${AppConstants.formatBytes(availableSpace)}\n\nPlease free up disk space or choose another location.',
          );
          return;
        }
        setState(() {
          _isLoading = true;
          _statusMessage = 'Extracting archive...';
        });

        final success = await ArchiveService.extractArchive(
          _selectedFilePath!,
          result,
        );

        setState(() {
          _isLoading = false;
          _statusMessage = success
              ? 'Archive extracted successfully!'
              : 'Failed to extract archive';
        });

        if (success) {
          _showSuccessDialog(
              'Extraction Complete', 'Archive extracted to:\n$result');
        } else {
          String errorMessage = 'Could not extract the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Extraction Failed', errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showErrorDialog(
          'Error', 'An unexpected error occurred:\n${e.toString()}');
    }
  }

  Future<void> _compressFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final sourcePaths = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();

        if (sourcePaths.isEmpty) return;

        // Ask for destination archive name
        final archiveName = await _showArchiveNameDialog();
        if (archiveName == null || archiveName.isEmpty) return;

        final saveResult = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Archive',
          fileName: archiveName,
        );

        if (saveResult != null) {
          // Check if required tools are available for the chosen archive type
          final archiveType = ArchiveService.detectArchiveType(saveResult);
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
              _showErrorDialog(
                'Tool Not Found',
                SystemToolsChecker.getToolErrorMessage(requiredTool),
              );
              return;
            }
          }

          setState(() {
            _isLoading = true;
            _statusMessage =
                'Compressing ${sourcePaths.length} ${sourcePaths.length == 1 ? 'file' : 'files'}...';
          });

          final success = await ArchiveService.compressToArchive(
            sourcePaths,
            saveResult,
          );

          setState(() {
            _isLoading = false;
            _statusMessage = success
                ? 'Files compressed successfully!'
                : 'Failed to compress files';
          });

          if (success) {
            _showSuccessDialog(
              'Compression Complete',
              'Archive created at:\n$saveResult',
              filePath: saveResult,
            );
          } else {
            String errorMessage = 'Could not create the archive.';
            if (requiredTool != null) {
              errorMessage +=
                  '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
            }
            _showErrorDialog('Compression Failed', errorMessage);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _compressDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        // Ask for destination archive name
        final archiveName = await _showArchiveNameDialog();
        if (archiveName == null || archiveName.isEmpty) return;

        final saveResult = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Archive',
          fileName: archiveName,
        );

        if (saveResult != null) {
          // Check if required tools are available for the chosen archive type
          final archiveType = ArchiveService.detectArchiveType(saveResult);
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
              _showErrorDialog(
                'Tool Not Found',
                SystemToolsChecker.getToolErrorMessage(requiredTool),
              );
              return;
            }
          }

          setState(() {
            _isLoading = true;
            _statusMessage = 'Compressing directory...';
          });

          final success = await ArchiveService.compressToArchive(
            [result],
            saveResult,
          );

          setState(() {
            _isLoading = false;
            _statusMessage = success
                ? 'Directory compressed successfully!'
                : 'Failed to compress directory';
          });

          if (success) {
            _showSuccessDialog(
              'Compression Complete',
              'Archive created at:\n$saveResult',
              filePath: saveResult,
            );
          } else {
            String errorMessage = 'Could not create the archive.';
            if (requiredTool != null) {
              errorMessage +=
                  '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
            }
            _showErrorDialog('Compression Failed', errorMessage);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _showArchiveOptions() async {
    // Check if there's a selected item from Downloads
    if (_downloadsSelectedIndex != null &&
        _downloadsSelectedIndex! < _downloadsContents.length) {
      final selectedEntity = _downloadsContents[_downloadsSelectedIndex!];
      final isFolder = selectedEntity is Directory;

      // Directly compress the selected item
      if (isFolder) {
        await _compressSpecificDirectory(selectedEntity.path);
      } else {
        await _compressSpecificFiles([selectedEntity.path]);
      }
      return;
    }

    // No selection - show options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.archive,
                color: Color(0xFF0066FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Create Archive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose what to archive:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF0066FF)),
              title: const Text('Compress Files'),
              subtitle: const Text('Select one or more files to compress'),
              onTap: () {
                Navigator.pop(context);
                _compressFiles();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Color(0xFF0066FF)),
              title: const Text('Compress Folder'),
              subtitle: const Text('Select a folder to compress'),
              onTap: () {
                Navigator.pop(context);
                _compressDirectory();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Compress specific files (from selection)
  Future<void> _compressSpecificFiles(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) return;

    try {
      // Ask for destination archive name
      final archiveName = await _showArchiveNameDialog();
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult != null) {
        // Check if required tools are available for the chosen archive type
        final archiveType = ArchiveService.detectArchiveType(saveResult);
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
            _showErrorDialog(
              'Tool Not Found',
              SystemToolsChecker.getToolErrorMessage(requiredTool),
            );
            return;
          }
        }

        setState(() {
          _isLoading = true;
          _statusMessage =
              'Compressing ${sourcePaths.length} ${sourcePaths.length == 1 ? 'file' : 'files'}...';
        });

        final success = await ArchiveService.compressToArchive(
          sourcePaths,
          saveResult,
        );

        setState(() {
          _isLoading = false;
          _statusMessage = success
              ? 'Files compressed successfully!'
              : 'Failed to compress files';
        });

        if (success) {
          _showSuccessDialog(
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
          );
        } else {
          String errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Compress specific directory (from selection)
  Future<void> _compressSpecificDirectory(String directoryPath) async {
    try {
      // Ask for destination archive name
      final archiveName = await _showArchiveNameDialog();
      if (archiveName == null || archiveName.isEmpty) return;

      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Archive',
        fileName: archiveName,
      );

      if (saveResult != null) {
        // Check if required tools are available for the chosen archive type
        final archiveType = ArchiveService.detectArchiveType(saveResult);
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
            _showErrorDialog(
              'Tool Not Found',
              SystemToolsChecker.getToolErrorMessage(requiredTool),
            );
            return;
          }
        }

        setState(() {
          _isLoading = true;
          _statusMessage = 'Compressing directory...';
        });

        final success = await ArchiveService.compressToArchive(
          [directoryPath],
          saveResult,
        );

        setState(() {
          _isLoading = false;
          _statusMessage = success
              ? 'Directory compressed successfully!'
              : 'Failed to compress directory';
        });

        if (success) {
          _showSuccessDialog(
            'Compression Complete',
            'Archive created at:\n$saveResult',
            filePath: saveResult,
          );
        } else {
          String errorMessage = 'Could not create the archive.';
          if (requiredTool != null) {
            errorMessage +=
                '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Compression Failed', errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<String?> _showArchiveNameDialog() async {
    String selectedFormat = '.zip';
    final controller = TextEditingController(text: 'archive');

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.archive,
                  color: Color(0xFF0066FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Archive',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archive Name:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter archive name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (value) => Navigator.pop(context, '$value$selectedFormat'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Format:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
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
                    _buildFormatChip('.tar.bz2', 'TAR.BZ2', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedFormat == '.7z'
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedFormat == '.7z'
                          ? Colors.orange.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedFormat == '.7z' ? Icons.info_outline : Icons.check_circle_outline,
                        size: 16,
                        color: selectedFormat == '.7z'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFormatInfoMessage(selectedFormat),
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedFormat == '.7z'
                                ? Colors.orange.shade900
                                : Colors.blue.shade900,
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
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Archive'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format, String label, String selectedFormat, Function(String) onSelect, {bool recommended = false}) {
    final isSelected = selectedFormat == format;
    return InkWell(
      onTap: () => onSelect(format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0066FF)
              : recommended
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
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
      case '.tar.bz2':
        return 'Better compression than GZIP • Native support';
      case '.tar':
        return 'Uncompressed archive • Fast • Native support';
      case '.7z':
        return 'Best compression ratio • Requires 7z tool (brew install p7zip)';
      default:
        return 'Native support • No additional tools required';
    }
  }

  void _showSuccessDialog(String title, String message, {String? filePath}) {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A00C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
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

  // Get items in current folder only
  List<String> _getItemsInCurrentPath(String basePath) {
    final items = <String>{};
    final prefix = basePath.isEmpty ? '' : '$basePath/';

    for (final item in _allArchiveContents) {
      if (item.startsWith(prefix)) {
        final relativePath = item.substring(prefix.length);
        if (relativePath.isEmpty) continue;

        // Check if this is a direct child
        final parts = relativePath.split('/');
        if (parts.length == 1 || (parts.length == 2 && parts[1].isEmpty)) {
          // Direct child (file or folder)
          items.add(item);
        } else {
          // Nested item - add only the immediate folder
          final folderName = parts[0];
          items.add('$prefix$folderName/');
        }
      }
    }

    return items.toList()..sort();
  }

  // Navigate into a folder
  void _navigateToFolder(String folderPath) {
    setState(() {
      // Exit search mode when navigating
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

  // Navigate back
  void _navigateBack() {
    if (_currentPath.isEmpty) return;

    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty ? '' : parts.join('/');

    _navigateToFolder(newPath);
  }

  // Preview nested archive file
  Future<void> _previewNestedArchive(String archiveItemPath) async {
    try {
      // Extract the nested archive to a temporary location
      final tempDir = Directory.systemTemp.createTempSync('winzipper_preview_');

      setState(() {
        _isLoading = true;
        _statusMessage = 'Extracting nested archive...';
      });

      // Extract only this specific file from the main archive
      final success = await ArchiveService.extractSpecificFile(
        _selectedFilePath!,
        archiveItemPath,
        tempDir.path,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to extract nested archive';
        });
        _showErrorDialog(
          'Preview Failed',
          'Could not extract the nested archive for preview.',
        );
        return;
      }

      // Get the extracted file path
      final extractedFileName = path.basename(archiveItemPath);
      final extractedFilePath = path.join(tempDir.path, extractedFileName);
      final extractedFile = File(extractedFilePath);

      if (!await extractedFile.exists()) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Extracted file not found';
        });
        _showErrorDialog(
          'Preview Failed',
          'The extracted archive file was not found.',
        );
        return;
      }

      // List contents of the nested archive
      final nestedContents = await ArchiveService.listArchiveContents(
        extractedFilePath,
      );

      // Clean up temp file
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }

      if (nestedContents.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Nested archive is empty';
        });
        _showErrorDialog(
          'Preview',
          'The nested archive "$extractedFileName" is empty.',
        );
        return;
      }

      // Show preview dialog
      setState(() {
        _isLoading = false;
      });

      _showNestedArchivePreviewDialog(extractedFileName, nestedContents);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showErrorDialog(
        'Preview Error',
        'An error occurred while previewing the nested archive:\n${e.toString()}',
      );
    }
  }

  void _showNestedArchivePreviewDialog(
      String archiveName, List<String> contents) {
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
              child: const Icon(
                Icons.archive,
                color: Color(0xFFF6A00C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archiveName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$folders folders, $files files',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Kind',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Content List
              Expanded(
                child: ListView.builder(
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final item = contents[index];
                    final itemName = path.basename(item);
                    final isFolder = item.endsWith('/');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? Colors.grey.shade50
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFolder ? Icons.folder : _getFileIcon(itemName),
                            size: 18,
                            color: isFolder
                                ? const Color(0xFFF6A00C)
                                : _getFileColor(itemName),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              itemName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              isFolder ? 'Folder' : _getFileKind(itemName),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top toolbar - always visible
        _buildTopToolbar(),
        // Content
        if (_isLoading)
          Expanded(child: _buildLoadingState())
        else if (_archiveContents.isNotEmpty)
          Expanded(child: _buildArchiveContents())
        else
          Expanded(child: _buildEmptyState()),
      ],
    );
  }

  // New top toolbar like macOS Finder - single row
  Widget _buildTopToolbar() {
    final fileName = _selectedFilePath != null ? path.basename(_selectedFilePath!) : 'Product Files.rar';
    final hasArchive = _selectedFilePath != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD1D1D6), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Archive title
          Icon(Icons.archive, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 6),
          Text(
            fileName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 24),
          // Toolbar buttons
          _buildToolbarButtonNew(Icons.archive_outlined, 'Archive', () => _showArchiveOptions()),
          _buildToolbarButtonNew(Icons.folder_open, 'Open', () => _pickArchiveFile()),
          _buildToolbarButtonNew(Icons.unarchive, 'Extract', hasArchive ? () => _extractArchive() : null),
          _buildToolbarButtonNew(Icons.search, 'Find', hasArchive ? () {
            setState(() => _isSearching = true);
          } : null),
          _buildToolbarButtonNew(Icons.visibility_outlined, 'View',
              _selectedIndex != null ? () => _viewSelectedFile() : null),
          _buildToolbarButtonNew(Icons.info_outline, 'Info',
              _selectedIndex != null ? () => _showFileInfo() : null),
          _buildToolbarButtonNew(Icons.cloud_upload_outlined, 'Share',
              hasArchive ? () => CloudUploadDialog.show(context, _selectedFilePath!) : null),
        ],
      ),
    );
  }

  Widget _buildToolbarButtonNew(IconData icon, String label, VoidCallback? onTap) {
    final isDisabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isDisabled ? const Color(0xFFBDBDC1) : const Color(0xFF6E6E73),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDisabled ? const Color(0xFFBDBDC1) : const Color(0xFF6E6E73),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveContents() {
    final folders = _archiveContents.where((item) => item.endsWith('/')).length;
    final files = _archiveContents.length - folders;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(),

          // Search Bar - appears below breadcrumb with animation
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isSearching ? _buildSearchBar() : const SizedBox.shrink(),
          ),

          // Table Header
          _buildTableHeader(),

          // Table Content
          Expanded(
            child: ListView.builder(
              itemCount: _archiveContents.length,
              itemBuilder: (context, index) {
                final item = _archiveContents[index];
                final isFolder = item.endsWith('/');
                return _buildTableRow(item, isFolder, index);
              },
            ),
          ),

          // Footer Summary
          _buildFooterSummary(folders, files),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final folders = _downloadsContents.where((e) => e is Directory).length;
    final files = _downloadsContents.length - folders;

    // Calculate total size
    int totalSize = 0;
    for (final entity in _downloadsContents) {
      if (entity is File) {
        try {
          totalSize += entity.lengthSync();
        } catch (e) {
          // Ignore
        }
      }
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb - Downloads
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _currentDownloadsPath.isEmpty ? null : _navigateBackInDownloads,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 12,
                      color: _currentDownloadsPath.isEmpty
                          ? const Color(0xFFD1D1D6)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _currentDownloadsPath.isEmpty
                      ? null
                      : () => _loadDownloadsFolder(),
                  child: Text(
                    'Downloads',
                    style: TextStyle(
                      fontSize: 11,
                      color: _currentDownloadsPath.isEmpty
                          ? const Color(0xFF000000)
                          : const Color(0xFF6E6E73),
                      fontWeight: _currentDownloadsPath.isEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (_currentDownloadsPath.isNotEmpty) ...[
                  for (final segment in _currentDownloadsPath.split('/')) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right, size: 12, color: Color(0xFFC7C7CC)),
                    ),
                    Text(
                      segment,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF8E8E93)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'sort', child: Text('Sort by...')),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          _buildTableHeader(),

          // Downloads content
          Expanded(
            child: _downloadsContents.isEmpty
                ? const Center(
                    child: Text(
                      'Downloads folder is empty',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _downloadsContents.length,
                    itemBuilder: (context, index) {
                      final entity = _downloadsContents[index];
                      return _buildDownloadsRow(entity, index);
                    },
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total $folders ${folders == 1 ? 'folder' : 'folders'} and ${AppConstants.formatBytes(totalSize)} in $files ${files == 1 ? 'file' : 'files'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsRow(FileSystemEntity entity, int index) {
    final name = path.basename(entity.path);
    final isFolder = entity is Directory;
    final stat = entity.statSync();
    final isHovered = _downloadsHoveredIndex == index;
    final isSelected = _downloadsSelectedIndex == index;

    // Format date
    final modified = stat.modified;
    final now = DateTime.now();
    String dateStr;
    if (modified.year == now.year && modified.month == now.month && modified.day == now.day) {
      dateStr = 'Today, ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
    } else if (modified.year == now.year && modified.month == now.month && modified.day == now.day - 1) {
      dateStr = 'Yesterday, ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
    } else {
      dateStr = '${modified.day} ${_getMonthName(modified.month)} ${modified.year}, ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
    }

    // Get size
    String sizeStr = '--';
    if (!isFolder && entity is File) {
      try {
        sizeStr = AppConstants.formatBytes(entity.lengthSync());
      } catch (e) {
        sizeStr = '--';
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _downloadsHoveredIndex = index),
      onExit: (_) => setState(() => _downloadsHoveredIndex = null),
      child: InkWell(
        onTap: () {
          setState(() {
            _downloadsSelectedIndex = _downloadsSelectedIndex == index ? null : index;
          });
        },
        onDoubleTap: () async {
          if (isFolder) {
            // Navigate into folder
            _navigateToDownloadsFolder(name);
          } else {
            // Check if it's an archive file
            final ext = path.extension(name).toLowerCase();
            if (ext == '.zip' || ext == '.rar' || ext == '.7z' ||
                ext == '.tar' || ext == '.gz' || ext == '.bz2') {
              // Open archive
              await _openArchiveFromPath(entity.path);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0058D0)
                : isHovered
                    ? const Color(0xFFE8E8ED)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isFolder ? Icons.folder : _getFileIcon(name),
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : _getFileColor(name),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : const Color(0xFF000000),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  isFolder ? 'Folder' : _getFileKind(name),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  sizeStr,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50.withOpacity(0.8),
            Colors.grey.shade50.withOpacity(0.4),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: _isSearching ? _buildSearchBar() : _buildToolbarButtons(),
    );
  }

  Widget _buildToolbarButtons() {
    return Row(
      children: [
        _buildToolbarButton(
          Icons.unarchive_outlined,
          'Extract',
          () => _extractArchive(),
          isPrimary: true,
        ),
        const SizedBox(width: 6),
        _buildToolbarButton(Icons.search, 'Find', () {
          setState(() {
            _isSearching = true;
          });
        }),
        _buildToolbarButton(Icons.visibility_outlined, 'View',
            _selectedIndex != null ? () => _viewSelectedFile() : null),
        _buildToolbarButton(Icons.info_outline, 'Info',
            _selectedIndex != null ? () => _showFileInfo() : null),
        const Spacer(),
        // Keyboard hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100.withOpacity(0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.grey.shade300.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '⌘ + F to search',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final searchResults = _searchQuery.isEmpty
        ? _archiveContents.length
        : _allArchiveContents
            .where((item) =>
                item.toLowerCase().contains(_searchQuery.toLowerCase()))
            .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD1D1D6), width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF000000)),
                decoration: InputDecoration(
                  hintText: 'Search in archive...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF8E8E93)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Color(0xFF8E8E93)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _archiveContents = _getItemsInCurrentPath(_currentPath);
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                    if (query.isEmpty) {
                      _archiveContents = _getItemsInCurrentPath(_currentPath);
                    } else {
                      _archiveContents = _allArchiveContents
                          .where((item) =>
                              item.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              '$searchResults ${searchResults == 1 ? 'result' : 'results'}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6E6E73),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
                _archiveContents = _getItemsInCurrentPath(_currentPath);
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0066FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF0066FF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isPrimary = false,
  }) {
    final isDisabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPrimary
                  ? const Color(0xFFF6A00C).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isPrimary
                  ? Border.all(
                      color: const Color(0xFFF6A00C).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDisabled
                      ? Colors.grey.shade400
                      : isPrimary
                          ? const Color(0xFFF6A00C)
                          : Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled
                        ? Colors.grey.shade400
                        : isPrimary
                            ? const Color(0xFFF6A00C)
                            : Colors.grey.shade700,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (_isSearching) return const SizedBox.shrink();

    final fileName = _selectedFilePath != null ? path.basename(_selectedFilePath!) : '';
    final pathSegments = _currentPath.isEmpty
        ? <String>[]
        : _currentPath.split('/').where((s) => s.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _currentPath.isEmpty ? null : _navigateBack,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios,
                size: 12,
                color: _currentPath.isEmpty ? const Color(0xFFD1D1D6) : const Color(0xFF8E8E93),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _navigateToFolder(''),
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6E6E73),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          for (int i = 0; i < pathSegments.length; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, size: 12, color: Color(0xFFC7C7CC)),
            ),
            InkWell(
              onTap: () {
                final targetPath = pathSegments.sublist(0, i + 1).join('/');
                _navigateToFolder(targetPath);
              },
              child: Text(
                pathSegments[i],
                style: TextStyle(
                  fontSize: 11,
                  color: i == pathSegments.length - 1
                      ? const Color(0xFF000000)
                      : const Color(0xFF6E6E73),
                  fontWeight: i == pathSegments.length - 1
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
          const Spacer(),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF8E8E93)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort', child: Text('Sort by...')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbSegment({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLast ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLast
                ? const Color(0xFFF6A00C).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isLast
                    ? const Color(0xFFF6A00C)
                    : isFirst
                        ? const Color(0xFFF6A00C).withOpacity(0.7)
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isLast
                      ? const Color(0xFFF6A00C)
                      : Colors.grey.shade700,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final hasArchive = _selectedFilePath != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildColumnHeader('Name', 'name', hasArchive),
          ),
          Expanded(
            flex: 2,
            child: _buildColumnHeader('Date Modified', 'date', hasArchive),
          ),
          Expanded(
            flex: 2,
            child: _buildColumnHeader('Kind', 'kind', hasArchive),
          ),
          SizedBox(
            width: 80,
            child: _buildColumnHeader('Size', 'size', hasArchive, align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label, String sortKey, bool hasArchive, {TextAlign? align}) {
    final isActive = _sortBy == sortKey && !hasArchive;

    return InkWell(
      onTap: hasArchive ? null : () {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
            _sortAscending = true;
          }
          _sortDownloadsContents();
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (align == TextAlign.right) const Spacer(),
          Text(
            label,
            textAlign: align,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF0066FF) : const Color(0xFF6E6E73),
              letterSpacing: 0.2,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: const Color(0xFF0066FF),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableRow(String item, bool isFolder, int index) {
    final fileName = path.basename(item);
    final isHovered = _hoveredIndex == index;
    final isSelected = _selectedIndex == index;
    final isZipFile = !isFolder &&
        (fileName.toLowerCase().endsWith('.zip') ||
            fileName.toLowerCase().endsWith('.rar') ||
            fileName.toLowerCase().endsWith('.7z'));

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = _selectedIndex == index ? null : index;
          });
        },
        onDoubleTap: () {
          if (isFolder) {
            final folderPath = item.endsWith('/') ? item.substring(0, item.length - 1) : item;
            _navigateToFolder(folderPath);
          } else if (isZipFile) {
            _previewNestedArchive(item);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0058D0)
                : isHovered
                    ? const Color(0xFFE8E8ED)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isFolder ? Icons.folder : _getFileIcon(fileName),
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : _getFileColor(fileName),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : const Color(0xFF000000),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Yesterday, 22:34',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  isFolder ? 'Folder' : _getFileKind(fileName),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  isFolder ? '--' : '2.54 MB',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSummary(int folders, int files) {
    final file = _selectedFilePath != null ? File(_selectedFilePath!) : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (file != null)
            FutureBuilder<int>(
              future: file.length(),
              builder: (context, snapshot) {
                final totalSize = snapshot.hasData
                    ? AppConstants.formatBytes(snapshot.data!)
                    : '5.2 MB';
                return Text(
                  'Total $folders ${folders == 1 ? 'folder' : 'folders'} and $totalSize in $files ${files == 1 ? 'file' : 'files'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8E8E93),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

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
        return 'Microsoft Document';
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


  // View selected file
  Future<void> _viewSelectedFile() async {
    if (_selectedIndex == null || _selectedIndex! >= _archiveContents.length) {
      return;
    }

    final selectedItem = _archiveContents[_selectedIndex!];
    if (selectedItem.endsWith('/')) {
      // It's a folder, navigate into it
      _navigateToFolder(
          selectedItem.substring(0, selectedItem.length - 1));
      return;
    }

    // Check if it's a text file
    final ext = path.extension(selectedItem).toLowerCase();
    final isTextFile = ['.txt', '.md', '.json', '.xml', '.csv', '.log']
        .contains(ext);

    if (!isTextFile) {
      _showErrorDialog(
        'Preview Not Supported',
        'File preview is only available for text files (.txt, .md, .json, .xml, .csv, .log).\n\nTo view other files, extract the archive first.',
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Loading file preview...';
      });

      // Extract to temp directory
      final tempDir = Directory.systemTemp.createTempSync('winzipper_view_');
      final success = await ArchiveService.extractSpecificFile(
        _selectedFilePath!,
        selectedItem,
        tempDir.path,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          'Preview Failed',
          'Could not extract file for preview.',
        );
        return;
      }

      final fileName = path.basename(selectedItem);
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          'Preview Failed',
          'Extracted file not found.',
        );
        return;
      }

      final content = await file.readAsString();

      // Clean up
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }

      setState(() {
        _isLoading = false;
      });

      _showFilePreviewDialog(fileName, content);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
        'Preview Error',
        'An error occurred while previewing the file:\n${e.toString()}',
      );
    }
  }

  void _showFilePreviewDialog(String fileName, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getFileIcon(fileName),
              color: _getFileColor(fileName),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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

  // Show file info
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
                color:
                    isFolder ? const Color(0xFFF6A00C) : _getFileColor(selectedItem),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'File Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
}
