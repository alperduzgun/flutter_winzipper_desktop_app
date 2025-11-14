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
    required this.getFileIcon,
    required this.getFileKind,
    required this.getFileColor,
    required this.getMonthName,
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
  final IconData Function(String) getFileIcon;
  final String Function(String) getFileKind;
  final Color Function(String) getFileColor;
  final String Function(int) getMonthName;

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
      return const Center(
        child: Text(
          'Downloads folder is empty',
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      );
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) => _buildDownloadsRow(contents[index], index),
    );
  }

  Widget _buildDownloadsRow(FileSystemEntity entity, int index) {
    final name = path.basename(entity.path);
    final isFolder = entity is Directory;
    final stat = entity.statSync();
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;

    // Format date
    final modified = stat.modified;
    final now = DateTime.now();
    String dateStr;
    if (modified.year == now.year && modified.month == now.month && modified.day == now.day) {
      dateStr = 'Today';
    } else if (modified.year == now.year && modified.month == now.month && modified.day == now.day - 1) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${modified.day} ${getMonthName(modified.month)}';
    }

    // Check if it's an archive file
    final ext = path.extension(name).toLowerCase();
    final isArchive = ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'].contains(ext);

    return MouseRegion(
      onEnter: (_) => onHoverChanged(index),
      onExit: (_) => onHoverChanged(null),
      child: InkWell(
        onTap: () => onSelectChanged(selectedIndex == index ? null : index),
        onDoubleTap: () async {
          if (isFolder) {
            onNavigateToFolder(name);
          } else if (isArchive) {
            await onOpenArchive(entity.path);
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
                isFolder ? Icons.folder : getFileIcon(name),
                size: 16,
                color: isFolder
                    ? const Color(0xFFFFBE0B)
                    : isSelected
                        ? Colors.white
                        : getFileColor(name),
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
                  isFolder ? 'Folder' : getFileKind(name),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6E6E73),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
