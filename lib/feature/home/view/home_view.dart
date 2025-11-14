part 'widgets/_window_controls.dart';
part 'widgets/_home_sidebar.dart';
part 'widgets/_home_content_area.dart';

import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../../../core/style/app_theme.dart';
import 'home_screen.dart';

/// Home feature - Main screen with sidebar and content
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Desktop: Show sidebar + content with window controls
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return Row(
        children: const [
          _HomeSidebar(),
          _HomeContentArea(),
        ],
      );
    }

    // Mobile: Just show content
    return const HomeScreen();
  }
}
