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
    Clipboard.setData(ClipboardData(text: widget.state.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Upload Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Filename
          Text(
            widget.state.fileName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // QR Code toggle
          if (_showQR) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: widget.state.url,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to download',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Link display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.state.url,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 18,
                  ),
                  onPressed: _copyToClipboard,
                  tooltip: _copied ? 'Copied!' : 'Copy link',
                  color: _copied ? Colors.green : Colors.grey.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showQR = !_showQR),
                icon: Icon(_showQR ? Icons.link : Icons.qr_code_2),
                label: Text(_showQR ? 'Show Link' : 'Show QR Code'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_copied ? Icons.check : Icons.copy),
                label: Text(_copied ? 'Copied!' : 'Copy Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6A00C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Link expires in 72 hours (3 days)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Close button
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
