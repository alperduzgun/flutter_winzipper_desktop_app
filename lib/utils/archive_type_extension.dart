import '../feature/home/models/archive_view_state.dart';

/// Archive type extension
///
/// Replaces getArchiveTypeLabel method
extension ArchiveTypeExtension on ArchiveType {
  String get label {
    switch (this) {
      case ArchiveType.zip:
        return 'ZIP Archive';
      case ArchiveType.rar:
        return 'RAR Archive';
      case ArchiveType.sevenZip:
        return '7-Zip Archive';
      case ArchiveType.tar:
        return 'TAR Archive';
      case ArchiveType.gzip:
        return 'GZIP Archive';
      case ArchiveType.bzip2:
        return 'BZIP2 Archive';
      default:
        return 'Archive';
    }
  }
}
