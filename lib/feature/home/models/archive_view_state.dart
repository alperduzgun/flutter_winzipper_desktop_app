import 'dart:io';

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
    this.selectedIndex,
    this.hoveredIndex,
    this.downloadsContents = const [],
    this.currentDownloadsPath = '',
    this.downloadsHoveredIndex,
    this.downloadsSelectedIndex,
  });

  final String? selectedFilePath;
  final List<String> archiveContents;
  final List<String> allArchiveContents;
  final bool isLoading;
  final String statusMessage;
  final ArchiveType currentArchiveType;
  final String currentPath;
  final int? selectedIndex;
  final int? hoveredIndex;
  final List<FileSystemEntity> downloadsContents;
  final String currentDownloadsPath;
  final int? downloadsHoveredIndex;
  final int? downloadsSelectedIndex;

  bool get hasArchive => selectedFilePath != null;

  ArchiveViewState copyWith({
    String? selectedFilePath,
    List<String>? archiveContents,
    List<String>? allArchiveContents,
    bool? isLoading,
    String? statusMessage,
    ArchiveType? currentArchiveType,
    String? currentPath,
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
