import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/archive_service.dart';
import '../utils/system_tools_checker.dart';

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
        setState(() {
          _selectedFilePath = result.files.single.path;
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
              ? 'No files found in archive'
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
      // Check if required tools are available for this archive type
      String? requiredTool;
      if (_currentArchiveType == ArchiveType.rar) {
        requiredTool = 'unrar';
      } else if (_currentArchiveType == ArchiveType.sevenZip) {
        requiredTool = '7z';
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
            requiredTool = 'rar';
          } else if (archiveType == ArchiveType.sevenZip) {
            requiredTool = '7z';
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
            _showSuccessDialog('Compression Complete', 'Archive created at:\n$saveResult');
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
            requiredTool = 'rar';
          } else if (archiveType == ArchiveType.sevenZip) {
            requiredTool = '7z';
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
            _showSuccessDialog('Compression Complete', 'Archive created at:\n$saveResult');
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

  void _showSuccessDialog(String title, String message) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Actions
            if (_selectedFilePath == null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.folder_open,
                      title: 'Open Archive',
                      description: 'Browse and extract',
                      color: const Color(0xFFF6A00C),
                      onTap: _pickArchiveFile,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.compress,
                      title: 'Compress Files',
                      description: 'Create new archive',
                      color: const Color(0xFF805306),
                      onTap: _compressFiles,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.folder_zip,
                      title: 'Compress Folder',
                      description: 'Archive directory',
                      color: const Color(0xFFFFD500),
                      onTap: _compressDirectory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Selected archive info
            if (_selectedFilePath != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6A00C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.archive,
                              color: Color(0xFFF6A00C),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.basename(_selectedFilePath!),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getArchiveTypeLabel(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearSelection,
                            tooltip: 'Clear selection',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilePath!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _extractArchive,
                              icon: const Icon(Icons.unarchive),
                              label: const Text('Extract Archive'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF6A00C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.blue.shade50
                      : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isLoading
                        ? Colors.blue.shade200
                        : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                            ? Colors.red
                            : Colors.green,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Archive contents
            if (_archiveContents.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.list, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Archive Contents',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6A00C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_archiveContents.length} ${_archiveContents.length == 1 ? 'item' : 'items'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _archiveContents.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _archiveContents[index];
                            final isFolder = item.endsWith('/');
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isFolder ? Icons.folder : Icons.insert_drive_file,
                                color: isFolder
                                    ? const Color(0xFFF6A00C)
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                              title: Text(
                                item,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.archive_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Archive Selected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open an archive or create a new one to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Supported Formats',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
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
                          ],
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}
