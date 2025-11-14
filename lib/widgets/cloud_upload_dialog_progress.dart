part of cloud_upload_dialog;

/// Progress view during upload
class _CloudUploadProgressView extends StatelessWidget {
  final CloudUploadInProgress? state;

  const _CloudUploadProgressView({this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF6A00C).withOpacity(0.15),
                  const Color(0xFFF6A00C).withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF6A00C).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.cloud_upload,
              color: Color(0xFFF6A00C),
              size: 52,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          const Text(
            'Uploading to Cloud',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),

          // Filename
          if (state != null)
            Text(
              state!.fileName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 28),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state?.progress ?? 0.0,
              backgroundColor: Colors.grey.shade200.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF6A00C),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),

          // Progress text
          Text(
            state != null
                ? '${(state!.progress * 100).toStringAsFixed(0)}%'
                : 'Starting upload...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 28),

          // Info text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'File will be available for 72 hours (3 days)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
