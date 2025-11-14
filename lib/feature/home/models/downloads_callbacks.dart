/// Downloads view callbacks
class DownloadsCallbacks {
  const DownloadsCallbacks({
    required this.onNavigateToFolder,
    required this.onNavigateBack,
    required this.onOpenArchive,
    required this.onHoverChanged,
    required this.onSelectChanged,
    required this.onSortChanged,
  });

  final void Function(String) onNavigateToFolder;
  final VoidCallback onNavigateBack;
  final void Function(String) onOpenArchive;
  final void Function(int?) onHoverChanged;
  final void Function(int?) onSelectChanged;
  final void Function(String, bool) onSortChanged;
}
