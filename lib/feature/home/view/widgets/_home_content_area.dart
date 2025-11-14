part of '../home_view.dart';

/// Right side content area with window controls and main content
class _HomeContentArea extends StatelessWidget {
  const _HomeContentArea();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Title bar with window controls
            WindowTitleBarBox(
              child: Row(
                children: [
                  Expanded(child: MoveWindow()),
                  const _WindowButtons(),
                ],
              ),
            ),
            // Main content (HomeScreen)
            const Expanded(child: HomeScreen()),
          ],
        ),
      ),
    );
  }
}
