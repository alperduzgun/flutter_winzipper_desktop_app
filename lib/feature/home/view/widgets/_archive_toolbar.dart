part of '../home_screen.dart';

/// Archive toolbar (private to HomeScreen)
///
/// Single Responsibility: Action buttons for archive operations
///
/// NOTE: Currently unused but kept for future extensibility
/// Following Open/Closed Principle
class _ArchiveToolbar extends StatelessWidget {
  const _ArchiveToolbar({
    required this.onExtract,
    required this.onCompress,
    required this.onUpload,
    this.enabled = true,
  });

  final VoidCallback onExtract;
  final VoidCallback onCompress;
  final VoidCallback onUpload;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.folder_open,
            label: 'Extract',
            onPressed: enabled ? onExtract : null,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.compress,
            label: 'Compress',
            onPressed: enabled ? onCompress : null,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.cloud_upload,
            label: 'Upload',
            onPressed: enabled ? onUpload : null,
          ),
        ],
      ),
    );
  }
}

/// Action button (private helper)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
