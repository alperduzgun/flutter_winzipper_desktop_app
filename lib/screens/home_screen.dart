import 'dart:io';
import 'dart:ui';

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
  bool _isLoading = false;
  String _statusMessage = '';
  ArchiveType _currentArchiveType = ArchiveType.unknown;

  // Public methods to be called from main.dart
  void pickArchiveFile() => _pickArchiveFile();
  void compressFiles() => _compressFiles();
  void compressDirectory() => _compressDirectory();

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
                    final baseName =
                        path.basenameWithoutExtension(controller.text);
                    controller.text = '$baseName$value';
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                        value: '.zip', child: Text('.zip')),
                    const PopupMenuItem<String>(
                        value: '.tar', child: Text('.tar')),
                    const PopupMenuItem<String>(
                        value: '.tar.gz', child: Text('.tar.gz')),
                    const PopupMenuItem<String>(
                        value: '.tar.bz2', child: Text('.tar.bz2')),
                    const PopupMenuItem<String>(
                        value: '.7z', child: Text('.7z (requires 7z)')),
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
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedFilePath != null) _buildSelectedArchiveInfo(),
        const SizedBox(height: 16),
        if (_archiveContents.isNotEmpty || _isLoading)
          Expanded(child: _buildArchiveContents()),
        if (_archiveContents.isEmpty && _selectedFilePath == null && !_isLoading)
          Expanded(child: _buildEmptyState()),
      ],
    );
  }

  Widget _buildSelectedArchiveInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.75),
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.45),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF6A00C).withOpacity(0.12),
                blurRadius: 60,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveContents() {
    if (_isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.75),
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.45),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFF6A00C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_archiveContents.isEmpty) {
      return const SizedBox.shrink();
    }

    final folders = _archiveContents.where((item) => item.endsWith('/')).length;
    final files = _archiveContents.length - folders;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.75),
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.45),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF6A00C).withOpacity(0.08),
                blurRadius: 60,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toolbar
              _buildToolbar(),

              // Breadcrumb
              _buildBreadcrumb(),

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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
              Icons.unarchive, 'Extract', () => _extractArchive()),
          _buildToolbarButton(Icons.search, 'Find', () {}),
          _buildToolbarButton(Icons.visibility, 'View', () {}),
          _buildToolbarButton(Icons.info_outline, 'Info', () {}),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final fileName =
        _selectedFilePath != null ? path.basename(_selectedFilePath!) : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_left, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.archive, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
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
          SizedBox(
            width: 100,
            child: Text(
              'Size',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String item, bool isFolder, int index) {
    final fileName = path.basename(item);
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:
              index.isEven ? Colors.white.withOpacity(0.3) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isFolder
                    ? const Color(0xFFFFD500).withOpacity(0.2)
                    : Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isFolder ? Icons.folder : _getFileIcon(fileName),
                color:
                    isFolder ? const Color(0xFFF6A00C) : Colors.blue.shade700,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                isFolder ? 'Folder' : _getFileKind(fileName),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                isFolder ? '--' : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSummary(int folders, int files) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total $folders ${folders == 1 ? 'folder' : 'folders'} and $files ${files == 1 ? 'file' : 'files'}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
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
}
