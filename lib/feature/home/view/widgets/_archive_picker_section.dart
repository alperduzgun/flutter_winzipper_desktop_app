part of '../home_screen.dart';

/// Archive picker and content viewer (private to HomeScreen)
///
/// Single Responsibility: Display archive contents and actions
class _ArchivePickerSection extends StatelessWidget {
  const _ArchivePickerSection({
    required this.selectedFilePath,
    required this.archiveContents,
    required this.isLoading,
    required this.statusMessage,
    required this.currentArchiveType,
    required this.onPickFile,
    required this.onExtract,
    required this.onCloudUpload,
  });

  final String? selectedFilePath;
  final List<String> archiveContents;
  final bool isLoading;
  final String statusMessage;
  final ArchiveType currentArchiveType;
  final VoidCallback onPickFile;
  final VoidCallback onExtract;
  final VoidCallback onCloudUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
        ),
      ),
      child: Column(
        children: [
          // Toolbar
          _buildToolbar(context),

          const Divider(height: 1),

          // Content area
          Expanded(
            child: selectedFilePath == null
                ? _buildEmptyState(context)
                : isLoading
                    ? _buildLoadingState()
                    : _buildArchiveContents(context),
          ),

          // Status bar
          if (statusMessage.isNotEmpty)
            _StatusMessage(message: statusMessage),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            selectedFilePath == null
                ? 'No Archive Selected'
                : path.basename(selectedFilePath!),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (selectedFilePath != null) ...[
            _ToolbarButton(
              icon: Icons.folder_open,
              label: 'Extract',
              onPressed: onExtract,
            ),
            const SizedBox(width: 12),
            _ToolbarButton(
              icon: Icons.cloud_upload,
              label: 'Upload',
              onPressed: onCloudUpload,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading archive contents...'),
        ],
      ),
    );
  }

  Widget _buildArchiveContents(BuildContext context) {
    if (archiveContents.isEmpty) {
      return Center(
        child: Text(
          'Archive is empty',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: archiveContents.length,
      itemBuilder: (context, index) {
        final item = archiveContents[index];
        final isFolder = item.endsWith('/');

        return ListTile(
          leading: Icon(
            isFolder ? Icons.folder : Icons.insert_drive_file,
            color: isFolder ? Colors.amber : Colors.grey,
          ),
          title: Text(item),
          dense: true,
        );
      },
    );
  }
}

/// Toolbar button (private helper widget)
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
