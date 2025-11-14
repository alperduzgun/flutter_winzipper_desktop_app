import 'package:flutter/material.dart';
import '../utils/file_extensions.dart';

/// Dialog service
///
/// Extracts all dialog logic from HomeScreen
/// Follows Single Responsibility Principle
class DialogService {
  /// Show error dialog
  static Future<void> showError(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return;

    return showDialog(
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

  /// Show success dialog with optional cloud upload
  static Future<void> showSuccess(
    BuildContext context,
    String title,
    String message, {
    String? filePath,
    VoidCallback? onCloudUpload,
  }) async {
    if (!context.mounted) return;

    return showDialog(
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
          if (filePath != null && onCloudUpload != null) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onCloudUpload();
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

  /// Show archive name dialog with format selection
  static Future<String?> showArchiveName(BuildContext context) async {
    if (!context.mounted) return null;

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
                    _FormatChip('.zip', 'ZIP', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }, recommended: true),
                    _FormatChip('.tar.gz', 'TAR.GZ', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                    _FormatChip('.7z', '7-Zip', selectedFormat, (format) {
                      setDialogState(() => selectedFormat = format);
                    }),
                    _FormatChip('.tar', 'TAR', selectedFormat, (format) {
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
                          _getFormatInfo(selectedFormat),
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

  /// Show file preview dialog
  static Future<void> showFilePreview(
    BuildContext context,
    String fileName,
    String content,
  ) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(fileName.fileIcon, color: fileName.fileColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  /// Show file info dialog
  static Future<void> showFileInfo(
    BuildContext context,
    String fileName,
    String fileKind,
    String extension,
    String filePath,
    String archiveName,
    bool isFolder,
  ) async {
    if (!context.mounted) return;

    return showDialog(
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
                isFolder ? Icons.folder : fileName.fileIcon,
                color: isFolder ? const Color(0xFFF6A00C) : fileName.fileColor,
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
              _InfoRow('Name', fileName),
              const Divider(),
              _InfoRow('Type', fileKind),
              if (!isFolder) ...[
                const Divider(),
                _InfoRow('Extension', extension.isEmpty ? 'None' : extension),
              ],
              const Divider(),
              _InfoRow('Path', filePath),
              const Divider(),
              _InfoRow('Archive', archiveName),
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

  /// Show nested archive preview dialog
  static Future<void> showNestedArchivePreview(
    BuildContext context,
    String archiveName,
    List<String> contents,
  ) async {
    if (!context.mounted) return;

    final folders = contents.where((item) => item.endsWith('/')).length;
    final files = contents.length - folders;

    return showDialog(
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
                  Text(
                    archiveName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$folders folders, $files files',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                  ),
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
              final itemName = item.split('/').last;
              final isFolder = item.endsWith('/');
              return ListTile(
                leading: Icon(
                  isFolder ? Icons.folder : itemName.fileIcon,
                  size: 18,
                  color: isFolder ? const Color(0xFFF6A00C) : itemName.fileColor,
                ),
                title: Text(itemName, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  isFolder ? 'Folder' : itemName.fileKind,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
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

  static String _getFormatInfo(String format) {
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
}

/// Format chip widget
class _FormatChip extends StatelessWidget {
  const _FormatChip(
    this.format,
    this.label,
    this.selectedFormat,
    this.onSelect, {
    this.recommended = false,
  });

  final String format;
  final String label;
  final String selectedFormat;
  final Function(String) onSelect;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
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
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
