import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../models/downloads_view_state.dart';
import '../../models/downloads_callbacks.dart';
import '../../../../utils/file_extensions.dart';
import '../../../../utils/date_extensions.dart';

/// Downloads folder browser
///
/// Reduced from 16 parameters to 2
/// - state: All view state data
/// - callbacks: All callback functions
class DownloadsBrowserSection extends StatelessWidget {
  const DownloadsBrowserSection({
    super.key,
    required this.state,
    required this.callbacks,
  });

  final DownloadsViewState state;
  final DownloadsCallbacks callbacks;

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
            _buildHeader(),
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

  Widget _buildHeader() {
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
    final parts = state.currentPath.split('/').where((p) => p.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (state.currentPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: callbacks.onNavigateBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (state.currentPath.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.currentPath.isEmpty ? 'Downloads' : '.../${parts.last}',
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
              currentSort: state.sortBy,
              ascending: state.sortAscending,
              onSort: callbacks.onSortChanged,
            ),
          ),
          Expanded(
            child: _SortableHeader(
              label: 'Kind',
              sortKey: 'kind',
              currentSort: state.sortBy,
              ascending: state.sortAscending,
              onSort: callbacks.onSortChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (state.contents.isEmpty) {
      return const Center(
        child: Text(
          'Downloads folder is empty',
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.contents.length,
      itemBuilder: (context, index) => _buildDownloadsRow(state.contents[index], index),
    );
  }

  Widget _buildDownloadsRow(FileSystemEntity entity, int index) {
    final name = path.basename(entity.path);
    final isFolder = entity is Directory;
    final stat = entity.statSync();
    final isHovered = state.hoveredIndex == index;
    final isSelected = state.selectedIndex == index;

    // Format date
    final modified = stat.modified;
    final now = DateTime.now();
    String dateStr;
    if (modified.year == now.year &&
        modified.month == now.month &&
        modified.day == now.day) {
      dateStr = 'Today';
    } else if (modified.year == now.year &&
        modified.month == now.month &&
        modified.day == now.day - 1) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${modified.day} ${modified.month.monthName}';
    }

    // Check if it's an archive file
    final ext = path.extension(name).toLowerCase();
    final isArchive = ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'].contains(ext);

    return MouseRegion(
      onEnter: (_) => callbacks.onHoverChanged(index),
      onExit: (_) => callbacks.onHoverChanged(null),
      child: InkWell(
        onTap: () => callbacks.onSelectChanged(state.selectedIndex == index ? null : index),
        onDoubleTap: () async {
          if (isFolder) {
            callbacks.onNavigateToFolder(name);
          } else if (isArchive) {
            await callbacks.onOpenArchive(entity.path);
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
                  isFolder ? 'Folder' : name.fileKind,
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

/// Sortable column header
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
  final void Function(String, bool) onSort;

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
