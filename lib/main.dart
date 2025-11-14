// Don't forget to make the changes mentioned in
// https://github.com/bitsdojo/bitsdojo_window#getting-started

import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/config/api_options.dart';
import 'core/config/app_flavor.dart';

/// Main entry point for the application
/// Only handles bootstrap and window initialization
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (development by default)
  try {
    await dotenv.load(fileName: '.env.development');
  } catch (e) {
    // If env file doesn't exist, continue with defaults
  }

  // Configure flavor
  AppFlavor(
    name: 'WinZipper [DEV]',
    flavorType: FlavorType.development,
    apiOptions: ApiOptions.development(),
  );

  // Only initialize window features on desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    // Initialize flutter_acrylic first
    try {
      await Window.initialize();
    } catch (e) {
      // ignore: avoid_print
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
      win.title = 'WinZipper - Archive Manager';
      win.show();
    });
  }

  // Bootstrap and run app with new architecture
  await bootstrap(() => const App());
}
