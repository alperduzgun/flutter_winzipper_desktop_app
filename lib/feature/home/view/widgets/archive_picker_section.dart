import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:winzipper/common/constants.dart';
import 'package:winzipper/feature/home/models/archive_callbacks.dart';
import 'package:winzipper/feature/home/models/archive_view_state.dart';
import 'package:winzipper/utils/file_extensions.dart';

/// Archive picker and content viewer
///
/// Reduced from 28 parameters to 3
/// - state: All view state data
/// - callbacks: All callback functions
/// - searchController: TextEditingController (cannot be in state)
class ArchivePickerSection extends StatelessWidget {
  const ArchivePickerSection({
    required this.state,
    required this.callbacks,
    required this.searchController,
    super.key,
  });

  final ArchiveViewState state;
  final ArchiveCallbacks callbacks;
  final TextEditingController searchController;

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
            Icons.search,
            'Find',
            state.hasArchive ? () => callbacks.onSearchToggle(true) : null,
          ),
          _buildToolbarButton(
            Icons.visibility_outlined,
            'View',
            state.selectedIndex != null ? callbacks.onViewFile : null,
          ),
          _buildToolbarButton(
            Icons.info_outline,
            'Info',
            state.selectedIndex != null ? callbacks.onShowFileInfo : null,
          ),
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
                Icon(Icons.insert_drive_file,
                    size: 18, color: Color(0xFF6E6E73)),
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
    final folders =
        state.archiveContents.where((item) => item.endsWith('/')).length;
    final files = state.archiveContents.length - folders;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child:
                state.isSearching ? _buildSearchBar() : const SizedBox.shrink(),
          ),
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
          _buildFooterSummary(folders, files),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
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
              'No Archive Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select an archive from Downloads or pick a file',
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
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (state.isSearching) return const SizedBox.shrink();

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
            icon: const Icon(Icons.arrow_drop_down,
                size: 18, color: Color(0xFF8E8E93)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort', child: Text('Sort by...')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchResults = state.searchQuery.isEmpty
        ? state.archiveContents.length
        : state.allArchiveContents
            .where(
              (item) =>
                  item.toLowerCase().contains(state.searchQuery.toLowerCase()),
            )
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
                controller: searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF000000)),
                decoration: InputDecoration(
                  hintText: 'Search in archive...',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Color(0xFF8E8E93)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 14, color: Color(0xFF8E8E93)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            searchController.clear();
                            callbacks.onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: callbacks.onSearchChanged,
              ),
            ),
          ),
          if (state.searchQuery.isNotEmpty) ...[
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
              searchController.clear();
              callbacks.onSearchChanged('');
              callbacks.onSearchToggle(false);
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0066FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_up,
                      size: 14, color: Color(0xFF0066FF)),
                ],
              ),
            ),
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
            flex: 4,
            child: _buildColumnHeader('Name'),
          ),
          Expanded(
            flex: 2,
            child: _buildColumnHeader('Date Modified'),
          ),
          Expanded(
            flex: 2,
            child: _buildColumnHeader('Kind'),
          ),
          SizedBox(
            width: 80,
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
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
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
                width: 80,
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

  Widget _buildFooterSummary(int folders, int files) {
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
          if (state.selectedFilePath != null)
            FutureBuilder<int>(
              future: File(state.selectedFilePath!).length(),
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
}
