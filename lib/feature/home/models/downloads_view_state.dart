import 'dart:io';

/// Downloads view state data model
class DownloadsViewState {
  const DownloadsViewState({
    this.contents = const [],
    this.currentPath = '',
    this.hoveredIndex,
    this.selectedIndex,
    this.sortBy = 'name',
    this.sortAscending = true,
  });

  final List<FileSystemEntity> contents;
  final String currentPath;
  final int? hoveredIndex;
  final int? selectedIndex;
  final String sortBy;
  final bool sortAscending;

  DownloadsViewState copyWith({
    List<FileSystemEntity>? contents,
    String? currentPath,
    int? hoveredIndex,
    int? selectedIndex,
    String? sortBy,
    bool? sortAscending,
  }) {
    return DownloadsViewState(
      contents: contents ?? this.contents,
      currentPath: currentPath ?? this.currentPath,
      hoveredIndex: hoveredIndex ?? this.hoveredIndex,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
