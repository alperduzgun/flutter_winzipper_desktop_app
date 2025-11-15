part of '../home_view.dart';

/// Left sidebar with app branding and supported formats
class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
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
            const Spacer(),
            // App Icon and Title
            _buildAppHeader(),
            const Spacer(),
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD500), Color(0xFFF6A00C)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF6A00C).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.folder_zip,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'WinZipper',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF805306),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Icon(
            Icons.apple,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            'macOS',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
