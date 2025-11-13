import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration
class AppTheme {
  const AppTheme._();

  /// WinZipper brand color
  static const Color brandColor = Color(0xFFF6A00C);

  /// Light theme
  static ThemeData get light => _buildLightTheme();

  /// Dark theme
  static ThemeData get dark => _buildDarkTheme();

  /// Dark purple theme (legacy)
  static ThemeData get darkPurple => _customThemeBuilder(
        cardColor: const Color(0xFF180D2F),
        scaffoldBackgroundColor: const Color(0xFF0F0823),
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrangeAccent,
      );

  /// Dark blue theme (legacy)
  static ThemeData get darkBlue => _customThemeBuilder(
        cardColor: const Color(0xFF092045),
        scaffoldBackgroundColor: const Color(0xFF081231),
        primarySwatch: Colors.cyan,
        accentColor: Colors.cyan,
      );

  static ThemeData _buildLightTheme() {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      dividerColor: Colors.black12,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      cardTheme: const CardTheme(
        elevation: 3,
        shadowColor: Colors.black45,
      ),
      dialogTheme: DialogTheme(
        shape: _roundedShape,
        backgroundColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFFF6F4F6),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: _textButtonThemeData,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandColor, width: 2),
        ),
      ),
    ).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.cyan,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      dividerColor: Colors.white10,
      scaffoldBackgroundColor: const Color(0xFF1D1E1F),
      cardColor: const Color(0xFF2B2D2F),
      dialogTheme: DialogTheme(
        shape: _roundedShape,
        backgroundColor: const Color(0xFF1D1E1F),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.black54,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          backgroundColor: Colors.grey[850],
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: Colors.grey[800] ?? Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: _textButtonThemeData,
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: Colors.black12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandColor, width: 2),
        ),
      ),
    ).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData _customThemeBuilder({
    Color? cardColor,
    Color? scaffoldBackgroundColor,
    MaterialColor? primarySwatch,
    Color? accentColor,
    Brightness brightness = Brightness.dark,
  }) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return ThemeData(
      brightness: brightness,
      primarySwatch: primarySwatch,
      cardColor: cardColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        secondary: accentColor,
      ),
      dividerColor: Colors.white10,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          backgroundColor: Colors.grey[850],
          side: BorderSide(
            color: Colors.grey[800] ?? Colors.grey,
          ),
        ),
      ),
      textButtonTheme: _textButtonThemeData,
      popupMenuTheme: PopupMenuThemeData(
        shape: _roundedShape,
      ),
      dialogTheme: DialogTheme(
        shape: _roundedShape,
        backgroundColor: scaffoldBackgroundColor,
        titleTextStyle: ThemeData.dark().textTheme.displayLarge,
        contentTextStyle: ThemeData.dark().textTheme.bodyLarge,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Colors.black54,
      ),
      chipTheme: ThemeData.dark().chipTheme.copyWith(
            backgroundColor: Colors.black12,
          ),
    ).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextButtonThemeData get _textButtonThemeData {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  static RoundedRectangleBorder get _roundedShape {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  /// Get platform background color with acrylic/mica effects
  static Color platformBackgroundColor(BuildContext context) {
    final themeBrightness = Theme.of(context).brightness;
    final platformBrightness = Brightness.light;
    final brightnessMatches = themeBrightness == platformBrightness;

    if (Platform.isWindows) {
      final windowsBuild = _getWindowsBuild();
      if (windowsBuild >= 22000) {
        // Windows 11 - Mica effect
        Window.setEffect(
          effect: WindowEffect.mica,
          color: Theme.of(context).cardColor.withAlpha(0),
          dark: Theme.of(context).brightness == Brightness.dark,
        );
        return Colors.transparent;
      } else if (windowsBuild >= 10240) {
        // Windows 10 - Aero effect
        Window.setEffect(
          effect: WindowEffect.aero,
          color: Theme.of(context).cardColor.withAlpha(200),
        );
        return Colors.transparent;
      }
      return Theme.of(context).cardColor;
    }

    if (brightnessMatches && Platform.isMacOS) {
      Window.setEffect(
        effect: WindowEffect.sidebar,
        color: Colors.transparent,
      );
      return Colors.transparent;
    } else {
      return Theme.of(context).cardColor;
    }
  }

  static bool _isNumeric(String? s) {
    if (s == null) return false;
    return double.tryParse(s) != null;
  }

  static double _getWindowsBuild() {
    final osVer =
        Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\w\s\.]+'), '');
    final splitOsVer = osVer.split(' ');
    final nums = splitOsVer.where(_isNumeric).toList();
    return double.parse(nums.last);
  }
}
