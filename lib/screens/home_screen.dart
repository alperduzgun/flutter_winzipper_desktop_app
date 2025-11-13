import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/archive_service.dart';
import '../utils/system_tools_checker.dart';
import '../common/constants.dart';
import '../widgets/cloud_upload_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFilePath;
  List<String> _archiveContents = [];
  bool _isLoading = false;
  String _statusMessage = '';
  ArchiveType _currentArchiveType = ArchiveType.unknown;

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
          _currentArchiveType = ArchiveService.detectArchiveType(_selectedFilePath!);
        });

        final contents = await ArchiveService.listArchiveContents(
          _selectedFilePath!,
        );

        setState(() {
          _archiveContents = contents;
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

      if (result != null) {
        // Check disk space
        final availableSpace = await SystemToolsChecker.getAvailableDiskSpace(result);
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
          _showSuccessDialog('Extraction Complete', 'Archive extracted to:\n$result');
        } else {
          String errorMessage = 'Could not extract the archive.';
          if (requiredTool != null) {
            errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
          }
          _showErrorDialog('Extraction Failed', errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showErrorDialog('Error', 'An unexpected error occurred:\n${e.toString()}');
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
            final isAvailable = await SystemToolsChecker.isToolAvailable(requiredTool);
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
            _statusMessage = 'Compressing ${sourcePaths.length} ${sourcePaths.length == 1 ? 'file' : 'files'}...';
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
              errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
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
            final isAvailable = await SystemToolsChecker.isToolAvailable(requiredTool);
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
              errorMessage += '\n\n${SystemToolsChecker.getInstallationInstructions(requiredTool)}';
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

  Future<String?> _showArchiveNameDialog() async {
    final controller = TextEditingController(text: 'archive.zip');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Archive Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a name for your archive:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Archive name',
                hintText: 'archive.zip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String value) {
                    final baseName = path.basenameWithoutExtension(controller.text);
                    controller.text = '$baseName$value';
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: '.zip', child: Text('.zip')),
                    const PopupMenuItem<String>(value: '.tar', child: Text('.tar')),
                    const PopupMenuItem<String>(value: '.tar.gz', child: Text('.tar.gz')),
                    const PopupMenuItem<String>(value: '.tar.bz2', child: Text('.tar.bz2')),
                    const PopupMenuItem<String>(value: '.7z', child: Text('.7z (requires 7z)')),
                  ],
                ),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A00C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
      _statusMessage = '';
      _currentArchiveType = ArchiveType.unknown;
    });
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sidebar
            _buildSidebar(),
            const SizedBox(width: 20),

            // Main Content Area
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF6A00C).withOpacity(0.15),
                              const Color(0xFFF6A00C).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF6A00C).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.archive,
                          color: Color(0xFFF6A00C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'WinZipper',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: Colors.grey.shade200.withOpacity(0.5),
                  indent: 20,
                  endIndent: 20,
                ),

                const SizedBox(height: 12),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _buildSidebarMenuItem(
                  icon: Icons.folder_open,
                  title: 'Open Archive',
                  color: const Color(0xFFF6A00C),
                  onTap: _pickArchiveFile,
                ),

                _buildSidebarMenuItem(
                  icon: Icons.compress,
                  title: 'Compress Files',
                  color: const Color(0xFF805306),
                  onTap: _compressFiles,
                ),

                _buildSidebarMenuItem(
                  icon: Icons.folder_zip,
                  title: 'Compress Folder',
                  color: const Color(0xFFFFD500),
                  onTap: _compressDirectory,
                ),

                const SizedBox(height: 20),

                Divider(
                  height: 1,
                  color: Colors.grey.shade200.withOpacity(0.5),
                  indent: 20,
                  endIndent: 20,
                ),

                const SizedBox(height: 12),

                // Supported Formats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'SUPPORTED FORMATS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFormatChip('ZIP'),
                      _buildFormatChip('RAR'),
                      _buildFormatChip('7-Zip'),
                      _buildFormatChip('TAR'),
                      _buildFormatChip('GZIP'),
                      _buildFormatChip('BZIP2'),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected archive info
        if (_selectedFilePath != null)
          ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF6A00C).withOpacity(0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFF6A00C).withOpacity(0.15),
                                      const Color(0xFFF6A00C).withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF6A00C).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.archive,
                                  color: Color(0xFFF6A00C),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      path.basename(_selectedFilePath!),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _getArchiveTypeLabel(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _clearSelection,
                                  tooltip: 'Clear selection',
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedFilePath!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _extractArchive,
                                  icon: const Icon(Icons.unarchive, size: 20),
                                  label: const Text(
                                    'Extract Archive',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF6A00C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shadowColor: const Color(0xFFF6A00C).withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isLoading
                            ? [
                                Colors.blue.shade50.withOpacity(0.9),
                                Colors.blue.shade50.withOpacity(0.6),
                              ]
                            : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                                ? [
                                    Colors.red.shade50.withOpacity(0.9),
                                    Colors.red.shade50.withOpacity(0.6),
                                  ]
                                : [
                                    Colors.green.shade50.withOpacity(0.9),
                                    Colors.green.shade50.withOpacity(0.6),
                                  ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLoading
                            ? Colors.blue.shade300.withOpacity(0.5)
                            : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                                ? Colors.red.shade300.withOpacity(0.5)
                                : Colors.green.shade300.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            ),
                          )
                        else
                          Icon(
                            _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            size: 20,
                            color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Archive contents
            if (_archiveContents.isNotEmpty)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.85),
                            Colors.white.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade50.withOpacity(0.9),
                                  Colors.grey.shade50.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.list, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Archive Contents',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFFF6A00C),
                                        const Color(0xFFF6A00C).withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF6A00C).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_archiveContents.length} ${_archiveContents.length == 1 ? 'item' : 'items'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _archiveContents.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade200.withOpacity(0.5),
                              ),
                              itemBuilder: (context, index) {
                                final item = _archiveContents[index];
                                final isFolder = item.endsWith('/');
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isFolder
                                          ? const Color(0xFFF6A00C).withOpacity(0.1)
                                          : Colors.grey.shade100.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isFolder ? Icons.folder : Icons.insert_drive_file,
                                      color: isFolder
                                          ? const Color(0xFFF6A00C)
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

        // Empty state
        if (_archiveContents.isEmpty && _selectedFilePath == null && !_isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade100.withOpacity(0.9),
                          Colors.grey.shade100.withOpacity(0.4),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.archive_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Archive Selected',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the sidebar to open or create an archive',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50.withOpacity(0.9),
            Colors.blue.shade50.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
