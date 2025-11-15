import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/config/app_flavor.dart';
import '../core/style/app_theme.dart';
import '../feature/home/view/home_view.dart';
import 'locator.dart';
import 'provider.dart';

/// Main application widget
/// Handles dependency injection and app configuration
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

        final blocProviders = provider();
        final child = MaterialApp(
          title: AppFlavor.instance().name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                ? WindowBorder(
                    color: const Color(0xFF805306),
                    width: 1,
                    child: const HomeView(),
                  )
                : const HomeView(),
          ),
        );

        return MultiRepositoryProvider(
          providers: snapshot.data!,
          child: blocProviders.isEmpty
              ? child
              : MultiBlocProvider(
                  providers: blocProviders,
                  child: child,
                ),
        );
      },
    );
  }
}
