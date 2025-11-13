import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/config/app_flavor.dart';
import '../core/style/app_theme.dart';
import '../screens/home_screen.dart';
import 'locator.dart';
import 'provider.dart';

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RepositoryProvider>>(
      future: locator(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MultiRepositoryProvider(
          providers: snapshot.data!,
          child: MultiBlocProvider(
            providers: provider(),
            child: MaterialApp(
              title: AppFlavor.instance().name,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
              home: Scaffold(
                body: (Platform.isMacOS ||
                        Platform.isWindows ||
                        Platform.isLinux)
                    ? WindowBorder(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                        child: const _MainLayout(),
                      )
                    : const HomeScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Main layout with window controls (desktop only)
class _MainLayout extends StatelessWidget {
  const _MainLayout();

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
                  const _WindowButtons(),
                ],
              ),
            ),
          ),
          // Main content
          const Expanded(child: HomeScreen()),
        ],
      ),
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

class _WindowButtons extends StatefulWidget {
  const _WindowButtons();

  @override
  State<_WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<_WindowButtons> {
  void maximizeOrRestore() {
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
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: _buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: _closeButtonColors),
      ],
    );
  }
}
