part of '../home_view.dart';

/// Window control buttons (minimize, maximize, close)
class _WindowButtons extends StatefulWidget {
  const _WindowButtons();

  @override
  State<_WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<_WindowButtons> {
  void _maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: _buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: _buttonColors,
                onPressed: _maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: _buttonColors,
                onPressed: _maximizeOrRestore,
              ),
        CloseWindowButton(colors: _closeButtonColors),
      ],
    );
  }
}

final _buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFFF6A00C),
  mouseDown: const Color(0xFF805306),
  iconMouseOver: const Color(0xFF805306),
  iconMouseDown: const Color(0xFFFFD500),
);

final _closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: Colors.white,
);
