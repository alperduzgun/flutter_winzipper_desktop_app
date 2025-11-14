part of '../home_view.dart';

/// Left sidebar with app branding and supported formats
class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.platformBackgroundColor(context),
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            WindowTitleBarBox(child: MoveWindow()),
            const SizedBox(height: 20),
            // App Icon and Title
            _buildAppHeader(),
            const Divider(),
            // Supported formats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPPORTED FORMATS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _FormatItem(icon: Icons.folder_zip, label: 'ZIP'),
                    const _FormatItem(icon: Icons.inventory_2, label: 'RAR'),
                    const _FormatItem(icon: Icons.archive, label: '7-Zip'),
                    const _FormatItem(icon: Icons.storage, label: 'TAR'),
                    const _FormatItem(icon: Icons.compress, label: 'GZIP'),
                    const _FormatItem(
                      icon: Icons.description,
                      label: 'BZIP2',
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD500), Color(0xFFF6A00C)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF6A00C).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.folder_zip,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'WinZipper',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF805306),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Archive Manager',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apple,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'macOS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Format item widget (private to sidebar)
class _FormatItem extends StatelessWidget {
  const _FormatItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
