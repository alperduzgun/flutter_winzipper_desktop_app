import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:winzipper/feature/home/models/archive_callbacks.dart';
import 'package:winzipper/feature/home/models/archive_view_state.dart';
import 'package:winzipper/utils/file_extensions.dart';

/// Archive picker and content viewer
///
/// Reduced from 28 parameters to 2
/// - state: All view state data
/// - callbacks: All callback functions
class ArchivePickerSection extends StatelessWidget {
  const ArchivePickerSection({
    required this.state,
    required this.callbacks,
    super.key,
  });

  final ArchiveViewState state;
  final ArchiveCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopToolbar(context),
          if (state.isLoading)
            Expanded(child: _buildLoadingState())
          else if (state.archiveContents.isNotEmpty)
            Expanded(child: _buildArchiveContents())
          else
            Expanded(child: _buildEmptyState()),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    final fileName = state.selectedFilePath != null
        ? path.basename(state.selectedFilePath!)
        : 'Product Files.rar';

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
          _buildToolbarButton(Icons.folder_open, 'Open', callbacks.onPickFile),
          _buildToolbarButton(
            Icons.unarchive,
            'Extract',
            state.hasArchive ? callbacks.onExtract : null,
          ),
          _buildCompressButton(context),
          _buildToolbarButton(
            Icons.cloud_upload_outlined,
            'Share',
            state.hasArchive ? callbacks.onCloudUpload : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback? onTap) {
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
                color: isDisabled
                    ? const Color(0xFFBDBDC1)
                    : const Color(0xFF6E6E73),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDisabled
                      ? const Color(0xFFBDBDC1)
                      : const Color(0xFF6E6E73),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompressButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        tooltip: 'Compress',
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.compress,
                size: 22,
                color: Color(0xFF6E6E73),
              ),
              SizedBox(height: 2),
              Text(
                'Compress',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6E6E73),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'files',
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 18,
                  color: Color(0xFF6E6E73),
                ),
                SizedBox(width: 12),
                Text('Compress Files...'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'directory',
            child: Row(
              children: [
                Icon(Icons.folder, size: 18, color: Color(0xFF6E6E73)),
                SizedBox(width: 12),
                Text('Compress Directory...'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'files') {
            callbacks.onCompressFiles();
          } else if (value == 'directory') {
            callbacks.onCompressDirectory();
          }
        },
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
              state.statusMessage,
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
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: state.archiveContents.length,
              itemBuilder: (context, index) {
                final item = state.archiveContents[index];
                final isFolder = item.endsWith('/');
                return _buildTableRow(item, isFolder, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDownloadsBreadcrumb(),
          _buildDownloadsTableHeader(),
          Expanded(
            child: state.downloadsContents.isEmpty
                ? _buildDownloadsEmptyFallback()
                : _buildDownloadsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsBreadcrumb() {
    final parts = state.currentDownloadsPath
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();

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
          if (state.currentDownloadsPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: callbacks.onDownloadsNavigateBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (state.currentDownloadsPath.isNotEmpty) const SizedBox(width: 8),
          Icon(Icons.download, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.currentDownloadsPath.isEmpty
                  ? 'Downloads'
                  : '.../${parts.last}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsTableHeader() {
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
            flex: 5,
            child: _buildColumnHeader('Name'),
          ),
          Expanded(
            flex: 3,
            child: _buildColumnHeader('Kind'),
          ),
          SizedBox(
            width: 100,
            child: _buildColumnHeader('Size', align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList() {
    return ListView.builder(
      itemCount: state.downloadsContents.length,
      itemBuilder: (context, index) {
        final entity = state.downloadsContents[index];
        return _buildDownloadsRow(entity, index);
      },
    );
  }

  Widget _buildDownloadsRow(FileSystemEntity entity, int index) {
    final name = path.basename(entity.path);
    final isFolder = entity is Directory;
    final isHovered = state.downloadsHoveredIndex == index;
    final isSelected = state.downloadsSelectedIndex == index;
    final stat = entity.statSync();

    final ext = path.extension(name).toLowerCase();
    final isArchive =
        ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'].contains(ext);

    return MouseRegion(
      onEnter: (_) => callbacks.onDownloadsHoverChanged(index),
      onExit: (_) => callbacks.onDownloadsHoverChanged(null),
      child: InkWell(
        onTap: () => callbacks.onDownloadsSelectChanged(
          state.downloadsSelectedIndex == index ? null : index,
        ),
        onDoubleTap: () {
          if (isFolder) {
            callbacks.onDownloadsNavigateToFolder(name);
          } else if (isArchive) {
            callbacks.onDownloadsOpenArchive(entity.path);
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
                isFolder ? Icons.folder : name.fileIcon,
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : name.fileColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
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
                flex: 3,
                child: Text(
                  isFolder ? 'Folder' : name.fileKind,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  isFolder
                      ? '--'
                      : entity is File
                          ? _formatBytes(stat.size)
                          : '--',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadsEmptyFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_zip_outlined,
            size: 120,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Downloads folder is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Or pick an archive file to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: callbacks.onPickFile,
            icon: const Icon(Icons.file_open),
            label: const Text('Pick Archive File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A00C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildBreadcrumb() {
    final fileName = state.selectedFilePath != null
        ? path.basename(state.selectedFilePath!)
        : '';
    final pathSegments = state.currentPath.isEmpty
        ? <String>[]
        : state.currentPath.split('/').where((s) => s.isNotEmpty).toList();

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
            onTap: state.currentPath.isEmpty ? null : callbacks.onNavigateBack,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios,
                size: 12,
                color: state.currentPath.isEmpty
                    ? const Color(0xFFD1D1D6)
                    : const Color(0xFF8E8E93),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => callbacks.onNavigateToFolder(''),
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
              child:
                  Icon(Icons.chevron_right, size: 12, color: Color(0xFFC7C7CC)),
            ),
            InkWell(
              onTap: () {
                final targetPath = pathSegments.sublist(0, i + 1).join('/');
                callbacks.onNavigateToFolder(targetPath);
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
            icon: const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort', child: Text('Sort by...')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
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
            flex: 5,
            child: _buildColumnHeader('Name'),
          ),
          Expanded(
            flex: 3,
            child: _buildColumnHeader('Kind'),
          ),
          SizedBox(
            width: 100,
            child: _buildColumnHeader('Size', align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label, {TextAlign? align}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (align == TextAlign.right) const Spacer(),
        Text(
          label,
          textAlign: align,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6E6E73),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String item, bool isFolder, int index) {
    final fileName = path.basename(item);
    final isHovered = state.hoveredIndex == index;
    final isSelected = state.selectedIndex == index;
    final isZipFile = !isFolder &&
        (fileName.toLowerCase().endsWith('.zip') ||
            fileName.toLowerCase().endsWith('.rar') ||
            fileName.toLowerCase().endsWith('.7z'));

    return MouseRegion(
      onEnter: (_) => callbacks.onHoverChanged(index),
      onExit: (_) => callbacks.onHoverChanged(null),
      child: InkWell(
        onTap: () {
          callbacks
              .onSelectChanged(state.selectedIndex == index ? null : index);
        },
        onDoubleTap: () {
          if (isFolder) {
            final folderPath =
                item.endsWith('/') ? item.substring(0, item.length - 1) : item;
            callbacks.onNavigateToFolder(folderPath);
          } else if (isZipFile) {
            callbacks.onPreviewNestedArchive(item);
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
                isFolder ? Icons.folder : fileName.fileIcon,
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : fileName.fileColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
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
                flex: 3,
                child: Text(
                  isFolder ? 'Folder' : fileName.fileKind,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  isFolder ? '--' : '2.54 MB',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
