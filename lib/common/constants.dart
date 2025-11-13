/// Application-wide constants
class AppConstants {
  // Archive size limits
  static const int maxArchiveSizeBytes = 2 * 1024 * 1024 * 1024; // 2GB
  static const int maxExtractedSizeBytes = 10 * 1024 * 1024 * 1024; // 10GB
  static const int maxFilesInArchive = 100000;

  // Disk space estimation
  static const int diskSpaceMultiplier = 3; // Estimate 3x archive size needed

  // Process timeouts
  static const Duration extractTimeout = Duration(minutes: 5);
  static const Duration compressTimeout = Duration(minutes: 10);

  // Display helpers
  static String formatBytes(int bytes) {
    return '${bytes ~/ (1024 * 1024)}MB';
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${bytes ~/ 1024} KB';
    if (bytes < 1024 * 1024 * 1024) return '${bytes ~/ (1024 * 1024)} MB';
    return '${bytes ~/ (1024 * 1024 * 1024)} GB';
  }
}
