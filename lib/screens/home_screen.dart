import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/archive_service.dart';

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
        });

        final contents = await ArchiveService.listArchiveContents(
          _selectedFilePath!,
        );

        setState(() {
          _archiveContents = contents;
          _isLoading = false;
          _statusMessage = 'Loaded ${contents.length} items';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _extractArchive() async {
    if (_selectedFilePath == null) return;

    try {
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
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
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
        if (archiveName == null) return;

        final saveResult = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Archive',
          fileName: archiveName,
        );

        if (saveResult != null) {
          setState(() {
            _isLoading = true;
            _statusMessage = 'Compressing files...';
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
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _compressDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        // Ask for destination archive name
        final archiveName = await _showArchiveNameDialog();
        if (archiveName == null) return;

        final saveResult = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Archive',
          fileName: archiveName,
        );

        if (saveResult != null) {
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
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<String?> _showArchiveNameDialog() async {
    final controller = TextEditingController(text: 'archive.zip');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter archive name',
            hintText: 'archive.zip',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'WinZipper',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF805306),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Archive Manager for macOS',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.folder_open,
                    label: 'Open Archive',
                    onPressed: _pickArchiveFile,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.compress,
                    label: 'Compress Files',
                    onPressed: _compressFiles,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.folder_zip,
                    label: 'Compress Folder',
                    onPressed: _compressDirectory,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Selected file info
            if (_selectedFilePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.archive, color: Color(0xFF805306)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              path.basename(_selectedFilePath!),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _extractArchive,
                            icon: const Icon(Icons.unarchive),
                            label: const Text('Extract'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF6A00C),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilePath!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isLoading) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Archive Contents (${_archiveContents.length} items)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _archiveContents.length,
                          itemBuilder: (context, index) {
                            final item = _archiveContents[index];
                            return ListTile(
                              leading: Icon(
                                item.endsWith('/')
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: const Color(0xFFF6A00C),
                              ),
                              title: Text(item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Supported formats info
            if (_archiveContents.isEmpty && _selectedFilePath == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Supported Formats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ZIP • RAR • 7Z • TAR • GZIP • BZIP2',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Open an archive or compress files to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: const Color(0xFFF6A00C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
