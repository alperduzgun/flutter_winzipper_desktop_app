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
      width: 450,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade50.withOpacity(0.9),
                  Colors.red.shade50.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.shade300.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.cloud_off,
              color: Colors.red.shade600,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Upload Failed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              error,
              textAlign: error.contains('\n') ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
