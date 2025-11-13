/// Cloud service API paths
enum CloudPath {
  /// Litterbox upload endpoint
  litterboxUpload('https://litterbox.catbox.moe/resources/internals/api.php');

  const CloudPath(this.path);
  final String path;
}
