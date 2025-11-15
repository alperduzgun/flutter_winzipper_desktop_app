/// Cloud service API paths
enum CloudPath {
  /// Catbox upload endpoint (permanent, returns files.catbox.moe URLs)
  /// Note: Using catbox.moe instead of litterbox because:
  /// - Litterbox (litter.catbox.moe) is blocked in Turkey by BTK
  /// - Catbox returns files.catbox.moe URLs which work globally
  litterboxUpload('https://catbox.moe/user/api.php');

  const CloudPath(this.path);
  final String path;
}
