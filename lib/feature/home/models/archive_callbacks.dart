/// Archive view callbacks
///
/// Groups all callback functions to reduce parameter count
class ArchiveCallbacks {
  const ArchiveCallbacks({
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
  });

  final VoidCallback onPickFile;
  final VoidCallback onExtract;
  final VoidCallback onCloudUpload;
  final void Function(String) onNavigateToFolder;
  final VoidCallback onNavigateBack;
  final VoidCallback onViewFile;
  final VoidCallback onShowFileInfo;
  final void Function(String) onPreviewNestedArchive;
  final void Function(String) onSearchChanged;
  final void Function(bool) onSearchToggle;
  final void Function(int?) onHoverChanged;
  final void Function(int?) onSelectChanged;
}
