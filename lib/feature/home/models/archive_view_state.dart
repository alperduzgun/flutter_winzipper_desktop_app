/// Archive view state data model
///
/// Reduces parameter count by grouping related state
class ArchiveViewState {
  const ArchiveViewState({
    this.selectedFilePath,
    this.archiveContents = const [],
    this.allArchiveContents = const [],
    this.isLoading = false,
    this.statusMessage = '',
    this.currentArchiveType = ArchiveType.unknown,
    this.currentPath = '',
    this.isSearching = false,
    this.searchQuery = '',
    this.selectedIndex,
    this.hoveredIndex,
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
  final int? selectedIndex;
  final int? hoveredIndex;

  bool get hasArchive => selectedFilePath != null;

  ArchiveViewState copyWith({
    String? selectedFilePath,
    List<String>? archiveContents,
    List<String>? allArchiveContents,
    bool? isLoading,
    String? statusMessage,
    ArchiveType? currentArchiveType,
    String? currentPath,
    bool? isSearching,
    String? searchQuery,
    int? selectedIndex,
    int? hoveredIndex,
  }) {
    return ArchiveViewState(
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      archiveContents: archiveContents ?? this.archiveContents,
      allArchiveContents: allArchiveContents ?? this.allArchiveContents,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
      currentArchiveType: currentArchiveType ?? this.currentArchiveType,
      currentPath: currentPath ?? this.currentPath,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      hoveredIndex: hoveredIndex ?? this.hoveredIndex,
    );
  }
}

enum ArchiveType {
  zip,
  rar,
  sevenZip,
  tar,
  gzip,
  bzip2,
  unknown,
}
