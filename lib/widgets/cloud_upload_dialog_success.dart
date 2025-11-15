part of cloud_upload_dialog;

/// Success view with link and QR code
class _CloudUploadSuccessView extends StatefulWidget {
  final CloudUploadSuccess state;

  const _CloudUploadSuccessView({required this.state});

  @override
  State<_CloudUploadSuccessView> createState() =>
      _CloudUploadSuccessViewState();
}

class _CloudUploadSuccessViewState extends State<_CloudUploadSuccessView> {
  bool _showQR = false;
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.state.uploadModel.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50.withOpacity(0.9),
                  Colors.green.shade50.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.shade300.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          const Text(
            'Upload Successful!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),

          // Filename
          Text(
            widget.state.uploadModel.fileName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 28),

          // QR Code toggle
          if (_showQR) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: widget.state.uploadModel.url,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Scan to download',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Link display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.state.uploadModel.url,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _copied
                        ? Colors.green.shade100.withOpacity(0.5)
                        : Colors.grey.shade200.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    onPressed: _copyToClipboard,
                    tooltip: _copied ? 'Copied!' : 'Copy link',
                    color:
                        _copied ? Colors.green.shade700 : Colors.grey.shade700,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _showQR = !_showQR),
                icon: Icon(_showQR ? Icons.link : Icons.qr_code_2, size: 18),
                label: Text(_showQR ? 'Show Link' : 'Show QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(
                    color: Colors.grey.shade300.withOpacity(0.6),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                label: Text(_copied ? 'Copied!' : 'Copy Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6A00C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Close button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Close'),
          ),
          const SizedBox(height: 16),

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
                const SizedBox(width: 10),
                Text(
                  'File stored permanently',
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
