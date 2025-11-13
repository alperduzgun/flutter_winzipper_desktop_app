part of cloud_upload_dialog;

/// Main content widget that switches between states
class _CloudUploadDialogContent extends StatelessWidget {
  const _CloudUploadDialogContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloudUploadCubit, CloudUploadState>(
      builder: (context, state) {
        if (state is CloudUploadInProgress) {
          return _CloudUploadProgressView(state: state);
        } else if (state is CloudUploadSuccess) {
          return _CloudUploadSuccessView(state: state);
        } else if (state is CloudUploadFailure) {
          return _CloudUploadErrorView(error: state.error);
        }

        // Initial state
        return const _CloudUploadProgressView(
          state: null,
        );
      },
    );
  }
}

/// Error view
class _CloudUploadErrorView extends StatelessWidget {
  final String error;

  const _CloudUploadErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off,
              color: Colors.red.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Upload Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              error,
              textAlign: error.contains('\n') ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
