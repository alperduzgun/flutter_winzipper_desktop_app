/// Application constants
class AppConstant {
  const AppConstant._();

  /// App name
  static const String appName = 'WinZipper';

  /// App version
  static const String appVersion = '0.1.0';

  /// Supported archive formats
  static const List<String> supportedFormats = [
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'xz',
  ];

  /// Maximum file size for cloud upload (in MB)
  static const int maxCloudUploadSizeMB = 1000;

  /// Cloud upload retention time (in hours)
  static const int cloudRetentionHours = 72;

  /// API timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 10);

  /// Storage keys
  static const String hiveBoxName = 'winzipper';
  static const String recentFilesKey = 'recent_files';
  static const String settingsKey = 'settings';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
}
