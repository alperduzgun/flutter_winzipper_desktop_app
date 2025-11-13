import 'dart:io';
import '../common/constants.dart';

/// Utility class to check if system tools are available
class SystemToolsChecker {
  /// Checks available disk space in bytes for a given path
  static Future<int> getAvailableDiskSpace(String dirPath) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('df', ['-k', dirPath]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length > 3) {
              final availableKB = int.tryParse(parts[3]) ?? 0;
              return availableKB * 1024; // Convert to bytes
            }
          }
        }
      } else if (Platform.isWindows) {
        // Windows: use wmic or fallback
        final result = await Process.run('wmic', ['logicaldisk', 'get', 'freespace']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final space = int.tryParse(lines[1].trim()) ?? 0;
            return space;
          }
        }
      }
    } catch (e) {
      print('Error checking disk space: $e');
    }
    // Return 100GB as fallback if we can't determine
    return 100 * 1024 * 1024 * 1024;
  }

  /// Checks if a specific command-line tool is available
  static Future<bool> isToolAvailable(String tool) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('which', [tool]);
        return result.exitCode == 0;
      } else if (Platform.isWindows) {
        final result = await Process.run('where', [tool]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Checks all required tools and returns their availability status
  static Future<Map<String, bool>> checkAllTools() async {
    return {
      AppConstants.toolUnrar: await isToolAvailable(AppConstants.toolUnrar),
      AppConstants.tool7zip: await isToolAvailable(AppConstants.tool7zip),
      AppConstants.toolRar: await isToolAvailable(AppConstants.toolRar),
    };
  }

  /// Gets installation instructions for a specific tool
  static String getInstallationInstructions(String tool) {
    if (Platform.isMacOS) {
      switch (tool) {
        case AppConstants.toolUnrar:
          return 'Install via Homebrew:\nbrew install unrar';
        case AppConstants.tool7zip:
          return 'Install via Homebrew:\nbrew install p7zip';
        case AppConstants.toolRar:
          return 'RAR compression requires WinRAR (commercial license).\n\nAlternatives:\n• Use ZIP format (built-in, free)\n• Use 7-Zip format (brew install p7zip)\n\nTo purchase WinRAR:\nhttps://www.rarlab.com';
        default:
          return 'Tool not found. Please install it manually.';
      }
    } else if (Platform.isLinux) {
      switch (tool) {
        case AppConstants.toolUnrar:
          return 'Install via package manager:\nsudo apt install unrar  # Debian/Ubuntu\nsudo dnf install unrar  # Fedora\nsudo pacman -S unrar    # Arch';
        case AppConstants.tool7zip:
          return 'Install via package manager:\nsudo apt install p7zip-full  # Debian/Ubuntu\nsudo dnf install p7zip       # Fedora\nsudo pacman -S p7zip         # Arch';
        case AppConstants.toolRar:
          return 'RAR compression requires WinRAR (commercial license).\n\nAlternatives:\n• Use ZIP format (built-in, free)\n• Use 7-Zip: sudo apt install p7zip-full\n\nTo purchase WinRAR:\nhttps://www.rarlab.com';
        default:
          return 'Tool not found. Please install it via your package manager.';
      }
    } else if (Platform.isWindows) {
      switch (tool) {
        case AppConstants.toolUnrar:
          return 'Download and install WinRAR from:\nhttps://www.rarlab.com/download.htm\n\nNote: UnRAR is free for extraction only.';
        case AppConstants.toolRar:
          return 'RAR compression requires WinRAR (commercial license).\n\nAlternatives:\n• Use ZIP format (built-in, free)\n• Use 7-Zip: https://www.7-zip.org\n\nTo purchase WinRAR:\nhttps://www.rarlab.com/download.htm';
        case AppConstants.tool7zip:
          return 'Download and install 7-Zip from:\nhttps://www.7-zip.org/download.html';
        default:
          return 'Tool not found. Please install it manually.';
      }
    }
    return 'Platform not supported.';
  }

  /// Gets a user-friendly error message with installation instructions
  static String getToolErrorMessage(String tool) {
    return 'The "$tool" tool is not installed.\n\n${getInstallationInstructions(tool)}';
  }

  /// Checks if the tool needed for a specific archive type is available
  static Future<bool> canHandleArchiveType(String archiveType) async {
    switch (archiveType.toLowerCase()) {
      case 'rar':
        return await isToolAvailable(AppConstants.toolUnrar);
      case '7z':
      case 'sevenzip':
        return await isToolAvailable(AppConstants.tool7zip);
      case 'zip':
      case 'tar':
      case 'gz':
      case 'gzip':
      case 'bz2':
      case 'bzip2':
        return true; // Native support
      default:
        return false;
    }
  }
}
