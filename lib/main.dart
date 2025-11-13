// Don't forget to make the changes mentioned in
// https://github.com/bitsdojo/bitsdojo_window#getting-started

import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import 'common/theme/theme.dart';
import 'screens/home_screen.dart';

// GlobalKey to access HomeScreen methods
final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize window features on desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    // Initialize flutter_acrylic first
    try {
      await Window.initialize();
    } catch (e) {
      print('Warning: Window.initialize failed: $e');
      // Continue anyway - window will work without acrylic effect
    }

    // Then configure bitsdojo_window
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(900, 700);
      win.minSize = initialSize;
      win.size = initialSize;

      win.alignment = Alignment.center;
      win.title = "WinZipper - Archive Manager";
      win.show();
    });
  }

  runApp(const MyApp());
}

const borderColor = Color(0xFF805306);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: const Color(0xFFE0E0E0),
          width: 1,
          child: const MainLayout(),
        ),
      ),
    );
  }
}

// Main Layout without sidebar
class MainLayout extends StatelessWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECEFF4), Color(0xFFD8DCE6)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Title bar with window controls
          WindowTitleBarBox(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: MoveWindow()),
                  const WindowButtons(),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(child: HomeScreen(key: homeScreenKey)),
        ],
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF805306),
    mouseOver: const Color(0xFFF6A00C),
    mouseDown: const Color(0xFF805306),
    iconMouseOver: const Color(0xFF805306),
    iconMouseDown: const Color(0xFFFFD500));

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: Colors.white);

class WindowButtons extends StatefulWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _WindowButtonsState createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
