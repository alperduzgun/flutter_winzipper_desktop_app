part of cloud_upload_dialog;

/// Progress view during upload
class _CloudUploadProgressView extends StatelessWidget {
  final CloudUploadInProgress? state;

  const _CloudUploadProgressView({this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6A00C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload,
              color: Color(0xFFF6A00C),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Uploading to Cloud',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Filename
          if (state != null)
            Text(
              state!.fileName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 24),

          // Progress bar
          LinearProgressIndicator(
            value: state?.progress ?? 0.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFF6A00C),
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 12),

          // Progress text
          Text(
            state != null
                ? '${(state!.progress * 100).toStringAsFixed(0)}%'
                : 'Starting upload...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Info text
          Text(
            'Your file will be available for 14 days',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
