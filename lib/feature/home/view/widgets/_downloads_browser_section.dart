part of '../home_screen.dart';

/// Downloads folder browser (private to HomeScreen)
///
/// Single Responsibility: Browse and select files from Downloads
class _DownloadsBrowserSection extends StatelessWidget {
  const _DownloadsBrowserSection({
    required this.contents,
    required this.currentPath,
    required this.hoveredIndex,
    required this.selectedIndex,
    required this.sortBy,
    required this.sortAscending,
    required this.onNavigateToFolder,
    required this.onNavigateBack,
    required this.onOpenArchive,
    required this.onHoverChanged,
    required this.onSelectChanged,
    required this.onSortChanged,
  });

  final List<FileSystemEntity> contents;
  final String currentPath;
  final int? hoveredIndex;
  final int? selectedIndex;
  final String sortBy;
  final bool sortAscending;
  final void Function(String folderName) onNavigateToFolder;
  final VoidCallback onNavigateBack;
  final void Function(String filePath) onOpenArchive;
  final void Function(int? index) onHoverChanged;
  final void Function(int? index) onSelectChanged;
  final void Function(String sortBy, bool ascending) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildBreadcrumb(),
            const Divider(height: 1),
            _buildColumnHeaders(),
            const Divider(height: 1),
            Expanded(child: _buildFileList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.download, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            'Downloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final parts = currentPath.split('/').where((p) => p.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (currentPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: onNavigateBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (currentPath.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: Text(
              currentPath.isEmpty ? 'Downloads' : '.../${parts.last}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SortableHeader(
              label: 'Name',
              sortKey: 'name',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSortChanged,
            ),
          ),
          Expanded(
            child: _SortableHeader(
              label: 'Kind',
              sortKey: 'kind',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSortChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (contents.isEmpty) {
      return Center(
        child: Text(
          'No files',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final entity = contents[index];
        final isDir = entity is Directory;
        final fileName = path.basename(entity.path);

        // Chaos Engineering: Check if archive file
        final isArchive = !isDir &&
            ['zip', 'rar', '7z', 'tar', 'gz', 'bz2']
                .any((ext) => fileName.toLowerCase().endsWith('.$ext'));

        return MouseRegion(
          onEnter: (_) => onHoverChanged(index),
          onExit: (_) => onHoverChanged(null),
          child: GestureDetector(
            onTap: () {
              onSelectChanged(index);
              if (isDir) {
                onNavigateToFolder(fileName);
              } else if (isArchive) {
                onOpenArchive(entity.path);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: selectedIndex == index
                  ? const Color(0xFFF6A00C).withOpacity(0.2)
                  : hoveredIndex == index
                      ? Colors.grey.shade200
                      : null,
              child: Row(
                children: [
                  Icon(
                    isDir ? Icons.folder : _getFileIcon(fileName),
                    size: 18,
                    color: isDir
                        ? Colors.amber.shade700
                        : isArchive
                            ? const Color(0xFFF6A00C)
                            : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isDir ? 'Folder' : _getFileKind(fileName),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'bz2':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileKind(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext.toUpperCase();
  }
}

/// Sortable column header (private helper)
class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.sortKey,
    required this.currentSort,
    required this.ascending,
    required this.onSort,
  });

  final String label;
  final String sortKey;
  final String currentSort;
  final bool ascending;
  final void Function(String sortKey, bool ascending) onSort;

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == sortKey;

    return GestureDetector(
      onTap: () {
        if (isActive) {
          onSort(sortKey, !ascending);
        } else {
          onSort(sortKey, true);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: Colors.black87,
            ),
          ],
        ],
      ),
    );
  }
}
