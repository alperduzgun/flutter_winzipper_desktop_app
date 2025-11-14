part of '../home_screen.dart';

/// Archive picker and content viewer (private to HomeScreen)
///
/// Single Responsibility: Display archive contents and actions
class _ArchivePickerSection extends StatelessWidget {
  const _ArchivePickerSection({
    required this.selectedFilePath,
    required this.archiveContents,
    required this.allArchiveContents,
    required this.isLoading,
    required this.statusMessage,
    required this.currentArchiveType,
    required this.currentPath,
    required this.isSearching,
    required this.searchQuery,
    required this.searchController,
    required this.selectedIndex,
    required this.hoveredIndex,
    required this.onPickFile,
    required this.onExtract,
    required this.onCloudUpload,
    required this.onNavigateToFolder,
    required this.onNavigateBack,
    required this.onViewFile,
    required this.onShowFileInfo,
    required this.onPreviewNestedArchive,
    required this.onSearchChanged,
    required this.onSearchToggle,
    required this.onHoverChanged,
    required this.onSelectChanged,
    required this.getFileIcon,
    required this.getFileKind,
    required this.getFileColor,
    required this.getArchiveTypeLabel,
  });

  final String? selectedFilePath;
  final List<String> archiveContents;
  final List<String> allArchiveContents;
  final bool isLoading;
  final String statusMessage;
  final ArchiveType currentArchiveType;
  final String currentPath;
  final bool isSearching;
  final String searchQuery;
  final TextEditingController searchController;
  final int? selectedIndex;
  final int? hoveredIndex;
  final VoidCallback onPickFile;
  final VoidCallback onExtract;
  final VoidCallback onCloudUpload;
  final Function(String) onNavigateToFolder;
  final VoidCallback onNavigateBack;
  final VoidCallback onViewFile;
  final VoidCallback onShowFileInfo;
  final Function(String) onPreviewNestedArchive;
  final Function(String) onSearchChanged;
  final Function(bool) onSearchToggle;
  final Function(int?) onHoverChanged;
  final Function(int?) onSelectChanged;
  final IconData Function(String) getFileIcon;
  final String Function(String) getFileKind;
  final Color Function(String) getFileColor;
  final String Function() getArchiveTypeLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top toolbar - always visible
          _buildTopToolbar(),
          // Content
          if (isLoading)
            Expanded(child: _buildLoadingState())
          else if (archiveContents.isNotEmpty)
            Expanded(child: _buildArchiveContents())
          else
            Expanded(child: _buildEmptyState()),
        ],
      ),
    );
  }

  // New top toolbar like macOS Finder - single row
  Widget _buildTopToolbar() {
    final fileName = selectedFilePath != null ? path.basename(selectedFilePath!) : 'Product Files.rar';
    final hasArchive = selectedFilePath != null;

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
          _buildToolbarButtonNew(Icons.folder_open, 'Open', () => onPickFile()),
          _buildToolbarButtonNew(Icons.unarchive, 'Extract', hasArchive ? () => onExtract() : null),
          _buildToolbarButtonNew(Icons.search, 'Find', hasArchive ? () {
            onSearchToggle(true);
          } : null),
          _buildToolbarButtonNew(Icons.visibility_outlined, 'View',
              selectedIndex != null ? () => onViewFile() : null),
          _buildToolbarButtonNew(Icons.info_outline, 'Info',
              selectedIndex != null ? () => onShowFileInfo() : null),
          _buildToolbarButtonNew(Icons.cloud_upload_outlined, 'Share',
              hasArchive ? () => onCloudUpload() : null),
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
              statusMessage,
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
    final folders = archiveContents.where((item) => item.endsWith('/')).length;
    final files = archiveContents.length - folders;

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
            child: isSearching ? _buildSearchBar() : const SizedBox.shrink(),
          ),

          // Table Header
          _buildTableHeader(),

          // Table Content
          Expanded(
            child: ListView.builder(
              itemCount: archiveContents.length,
              itemBuilder: (context, index) {
                final item = archiveContents[index];
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
              onPressed: onPickFile,
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
    if (isSearching) return const SizedBox.shrink();

    final fileName = selectedFilePath != null ? path.basename(selectedFilePath!) : '';
    final pathSegments = currentPath.isEmpty
        ? <String>[]
        : currentPath.split('/').where((s) => s.isNotEmpty).toList();

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
            onTap: currentPath.isEmpty ? null : onNavigateBack,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios,
                size: 12,
                color: currentPath.isEmpty ? const Color(0xFFD1D1D6) : const Color(0xFF8E8E93),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onNavigateToFolder(''),
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
                onNavigateToFolder(targetPath);
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

  Widget _buildSearchBar() {
    final searchResults = searchQuery.isEmpty
        ? archiveContents.length
        : allArchiveContents
            .where((item) =>
                item.toLowerCase().contains(searchQuery.toLowerCase()))
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
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF8E8E93)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Color(0xFF8E8E93)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
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
              onSearchChanged('');
              onSearchToggle(false);
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
                  Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF0066FF)),
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
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;
    final isZipFile = !isFolder &&
        (fileName.toLowerCase().endsWith('.zip') ||
            fileName.toLowerCase().endsWith('.rar') ||
            fileName.toLowerCase().endsWith('.7z'));

    return MouseRegion(
      onEnter: (_) => onHoverChanged(index),
      onExit: (_) => onHoverChanged(null),
      child: InkWell(
        onTap: () {
          onSelectChanged(selectedIndex == index ? null : index);
        },
        onDoubleTap: () {
          if (isFolder) {
            final folderPath = item.endsWith('/') ? item.substring(0, item.length - 1) : item;
            onNavigateToFolder(folderPath);
          } else if (isZipFile) {
            onPreviewNestedArchive(item);
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
                isFolder ? Icons.folder : getFileIcon(fileName),
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : getFileColor(fileName),
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
                  isFolder ? 'Folder' : getFileKind(fileName),
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
    final file = selectedFilePath != null ? File(selectedFilePath!) : null;
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
}
