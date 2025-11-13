import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path_pkg;
import '../../core/types/typedefs.dart';
import '../../utils/system_tools_checker.dart';
import '../../common/constants.dart';

/// Archive format types
enum ArchiveType {
  zip,
  tar,
  gzip,
  bzip2,
  sevenZip,
  rar,
  unknown,
}

/// Service interface for archive operations
abstract class IArchiveService {
  /// Extract archive to destination
  Future<bool> extractArchive(String archivePath, String destinationPath);

  /// Compress files to archive
  Future<bool> compressToArchive(
    List<String> sourcePaths,
    String destinationArchivePath,
  );

  /// List archive contents
  Future<List<String>> listArchiveContents(String archivePath);

  /// Extract specific file from archive
  Future<bool> extractSpecificFile(
    String archivePath,
    String fileInArchive,
    String destinationPath,
  );

  /// Detect archive type from file path
  ArchiveType detectArchiveType(String filePath);
}

/// Implementation of archive service
/// Handles extraction and compression of various archive formats
class ArchiveService implements IArchiveService {
  @override
  ArchiveType detectArchiveType(String filePath) {
    final extension = path_pkg.extension(filePath).toLowerCase();
    switch (extension) {
      case '.zip':
        return ArchiveType.zip;
      case '.tar':
        return ArchiveType.tar;
      case '.gz':
      case '.gzip':
        return ArchiveType.gzip;
      case '.bz2':
      case '.bzip2':
        return ArchiveType.bzip2;
      case '.7z':
        return ArchiveType.sevenZip;
      case '.rar':
        return ArchiveType.rar;
      default:
        return ArchiveType.unknown;
    }
  }

  @override
  Future<bool> extractArchive(
    String archivePath,
    String destinationPath,
  ) async {
    try {
      final file = File(archivePath);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        throw Exception(
          'Archive too large: ${AppConstants.formatBytes(fileSize)}. '
          'Max: ${AppConstants.formatBytes(AppConstants.maxArchiveSizeBytes)}',
        );
      }

      final availableSpace =
          await SystemToolsChecker.getAvailableDiskSpace(destinationPath);
      final estimatedNeeded = fileSize * AppConstants.diskSpaceMultiplier;

      if (availableSpace < estimatedNeeded) {
        throw Exception(
          'Insufficient disk space. '
          'Need ~${AppConstants.formatBytes(estimatedNeeded)}, '
          'have ${AppConstants.formatBytes(availableSpace)}',
        );
      }

      final archiveType = detectArchiveType(archivePath);
      final bytes = await File(archivePath).readAsBytes();

      Archive? archive;

      switch (archiveType) {
        case ArchiveType.zip:
          archive = ZipDecoder().decodeBytes(bytes);
        case ArchiveType.tar:
          archive = TarDecoder().decodeBytes(bytes);
        case ArchiveType.gzip:
          final decompressed = GZipDecoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            final outputFile =
                File(path_pkg.join(destinationPath, fileName));
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(decompressed);
            return true;
          }
        case ArchiveType.bzip2:
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            final outputFile =
                File(path_pkg.join(destinationPath, fileName));
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(decompressed);
            return true;
          }
        case ArchiveType.sevenZip:
        case ArchiveType.rar:
          return await _extractUsingSystemTools(
            archivePath,
            destinationPath,
            archiveType,
          );
        case ArchiveType.unknown:
          throw Exception('Unknown archive type');
      }

      if (archive != null) {
        await _extractArchiveToDirectory(archive, destinationPath);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Error extracting archive: $e');
    }
  }

  Future<void> _extractArchiveToDirectory(
    Archive archive,
    String destinationPath,
  ) async {
    int totalExtracted = 0;
    int totalSize = 0;

    for (final file in archive) {
      if (totalExtracted >= AppConstants.maxFilesInArchive) {
        throw Exception(
          'Too many files in archive (max ${AppConstants.maxFilesInArchive})',
        );
      }

      // Prevent path traversal (Zip Slip vulnerability)
      final filename =
          path_pkg.normalize(path_pkg.join(destinationPath, file.name));
      final canonicalDest = path_pkg.canonicalize(destinationPath);

      if (!filename.startsWith(canonicalDest)) {
        // Skip potentially malicious paths
        continue;
      }

      if (file.isFile) {
        final content = file.content as List<int>;
        totalSize += content.length;

        if (totalSize > AppConstants.maxExtractedSizeBytes) {
          throw Exception(
            'Extracted size exceeded limit '
            '(max ${AppConstants.formatSize(AppConstants.maxExtractedSizeBytes)})',
          );
        }

        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(content);
        totalExtracted++;
      } else {
        await Directory(filename).create(recursive: true);
      }
    }
  }

  Future<bool> _extractUsingSystemTools(
    String archivePath,
    String destinationPath,
    ArchiveType type,
  ) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      throw Exception(
        'System tools extraction only supported on macOS/Linux',
      );
    }

    String command;
    List<String> args;

    if (type == ArchiveType.sevenZip) {
      command = AppConstants.tool7zip;
      args = ['x', archivePath, '-o$destinationPath', '-y'];
    } else if (type == ArchiveType.rar) {
      command = AppConstants.toolUnrar;
      args = ['x', '-o+', archivePath, destinationPath];
    } else {
      return false;
    }

    final result = await Process.run(command, args).timeout(
      AppConstants.extractTimeout,
      onTimeout: () => ProcessResult(0, 124, '', 'Timeout'),
    );

    return result.exitCode == 0;
  }

  @override
  Future<bool> compressToArchive(
    List<String> sourcePaths,
    String destinationArchivePath,
  ) async {
    try {
      final archiveType = detectArchiveType(destinationArchivePath);
      final archive = Archive();

      for (final sourcePath in sourcePaths) {
        final entity = FileSystemEntity.typeSync(sourcePath);
        if (entity == FileSystemEntityType.file) {
          await _addFileToArchive(archive, sourcePath);
        } else if (entity == FileSystemEntityType.directory) {
          await _addDirectoryToArchive(archive, sourcePath);
        }
      }

      List<int>? encodedData;

      switch (archiveType) {
        case ArchiveType.zip:
          encodedData = ZipEncoder().encode(archive);
        case ArchiveType.tar:
          encodedData = TarEncoder().encode(archive);
        case ArchiveType.gzip:
          if (sourcePaths.length > 1 ||
              FileSystemEntity.typeSync(sourcePaths[0]) ==
                  FileSystemEntityType.directory) {
            final tarData = TarEncoder().encode(archive);
            encodedData = GZipEncoder().encode(tarData);
          } else {
            final fileBytes = await File(sourcePaths[0]).readAsBytes();
            encodedData = GZipEncoder().encode(fileBytes);
          }
        case ArchiveType.bzip2:
          if (sourcePaths.length > 1 ||
              FileSystemEntity.typeSync(sourcePaths[0]) ==
                  FileSystemEntityType.directory) {
            final tarData = TarEncoder().encode(archive);
            encodedData = BZip2Encoder().encode(tarData);
          } else {
            final fileBytes = await File(sourcePaths[0]).readAsBytes();
            encodedData = BZip2Encoder().encode(fileBytes);
          }
        case ArchiveType.sevenZip:
        case ArchiveType.rar:
          return await _compressUsingSystemTools(
            sourcePaths,
            destinationArchivePath,
            archiveType,
          );
        case ArchiveType.unknown:
          throw Exception('Unknown archive type');
      }

      if (encodedData != null) {
        final outputFile = File(destinationArchivePath);
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(encodedData);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Error compressing archive: $e');
    }
  }

  Future<void> _addFileToArchive(Archive archive, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archiveFile = ArchiveFile(
      path_pkg.basename(filePath),
      bytes.length,
      bytes,
    );
    archive.addFile(archiveFile);
  }

  Future<void> _addDirectoryToArchive(
    Archive archive,
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);
    final baseDir = path_pkg.basename(directoryPath);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final relativePath =
            path_pkg.relative(entity.path, from: directoryPath);
        final archivePath = path_pkg.join(baseDir, relativePath);
        final archiveFile =
            ArchiveFile(archivePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      }
    }
  }

  Future<bool> _compressUsingSystemTools(
    List<String> sourcePaths,
    String destinationArchivePath,
    ArchiveType type,
  ) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      throw Exception(
        'System tools compression only supported on macOS/Linux',
      );
    }

    String command;
    List<String> args;

    if (type == ArchiveType.sevenZip) {
      command = AppConstants.tool7zip;
      args = ['a', destinationArchivePath, ...sourcePaths];
    } else if (type == ArchiveType.rar) {
      command = AppConstants.toolRar;
      args = ['a', destinationArchivePath, ...sourcePaths];
    } else {
      return false;
    }

    final result = await Process.run(command, args).timeout(
      AppConstants.compressTimeout,
      onTimeout: () => ProcessResult(0, 124, '', 'Timeout'),
    );

    return result.exitCode == 0;
  }

  @override
  Future<List<String>> listArchiveContents(String archivePath) async {
    try {
      final file = File(archivePath);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxArchiveSizeBytes) {
        throw Exception(
          'Archive too large to list: ${AppConstants.formatBytes(fileSize)}',
        );
      }

      final archiveType = detectArchiveType(archivePath);
      final bytes = await File(archivePath).readAsBytes();

      Archive? archive;

      switch (archiveType) {
        case ArchiveType.zip:
          archive = ZipDecoder().decodeBytes(bytes);
        case ArchiveType.tar:
          archive = TarDecoder().decodeBytes(bytes);
        case ArchiveType.gzip:
          final decompressed = GZipDecoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            return [fileName];
          }
        case ArchiveType.bzip2:
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            return [fileName];
          }
        case ArchiveType.sevenZip:
        case ArchiveType.rar:
          return await _listUsingSystemTools(archivePath, archiveType);
        case ArchiveType.unknown:
          throw Exception('Unknown archive type');
      }

      if (archive != null) {
        return archive.map((file) => file.name).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error listing archive contents: $e');
    }
  }

  Future<List<String>> _listUsingSystemTools(
    String archivePath,
    ArchiveType type,
  ) async {
    String command;
    List<String> args;

    if (type == ArchiveType.sevenZip) {
      command = AppConstants.tool7zip;
      args = ['l', '-slt', archivePath];
    } else if (type == ArchiveType.rar) {
      command = AppConstants.toolUnrar;
      args = ['lb', archivePath];
    } else {
      return [];
    }

    final result = await Process.run(command, args).timeout(
      AppConstants.listTimeout,
      onTimeout: () => ProcessResult(0, 124, '', 'Timeout'),
    );

    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split('\n');

      if (type == ArchiveType.sevenZip) {
        return lines
            .where((line) => line.startsWith('Path = '))
            .map((line) => line.substring(7).trim())
            .where((name) => name.isNotEmpty)
            .toList();
      } else {
        return lines
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  @override
  Future<bool> extractSpecificFile(
    String archivePath,
    String fileInArchive,
    String destinationPath,
  ) async {
    final archiveType = detectArchiveType(archivePath);

    switch (archiveType) {
      case ArchiveType.zip:
      case ArchiveType.tar:
      case ArchiveType.gzip:
      case ArchiveType.bzip2:
        return await _extractSpecificFileNative(
          archivePath,
          fileInArchive,
          destinationPath,
          archiveType,
        );
      case ArchiveType.sevenZip:
      case ArchiveType.rar:
        return await _extractSpecificFileUsingSystemTools(
          archivePath,
          fileInArchive,
          destinationPath,
          archiveType,
        );
      case ArchiveType.unknown:
        return false;
    }
  }

  Future<bool> _extractSpecificFileNative(
    String archivePath,
    String fileInArchive,
    String destinationPath,
    ArchiveType archiveType,
  ) async {
    try {
      final bytes = await File(archivePath).readAsBytes();
      Archive? archive;

      switch (archiveType) {
        case ArchiveType.zip:
          archive = ZipDecoder().decodeBytes(bytes);
        case ArchiveType.tar:
          archive = TarDecoder().decodeBytes(bytes);
        case ArchiveType.gzip:
          final decompressed = GZipDecoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          }
        case ArchiveType.bzip2:
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          final fileName = path_pkg.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          }
        default:
          return false;
      }

      if (archive == null) return false;

      for (final file in archive) {
        if (file.name == fileInArchive && file.isFile) {
          final content = file.content as List<int>;
          final outputPath = path_pkg.join(
            destinationPath,
            path_pkg.basename(fileInArchive),
          );
          final outFile = File(outputPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(content);
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Error extracting specific file: $e');
    }
  }

  Future<bool> _extractSpecificFileUsingSystemTools(
    String archivePath,
    String fileInArchive,
    String destinationPath,
    ArchiveType type,
  ) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return false;
    }

    String command;
    List<String> args;

    if (type == ArchiveType.sevenZip) {
      command = AppConstants.tool7zip;
      args = ['e', archivePath, '-o$destinationPath', fileInArchive, '-y'];
    } else if (type == ArchiveType.rar) {
      command = AppConstants.toolUnrar;
      args = ['e', '-o+', archivePath, fileInArchive, destinationPath];
    } else {
      return false;
    }

    final result = await Process.run(command, args).timeout(
      const Duration(seconds: 30),
      onTimeout: () => ProcessResult(0, 124, '', 'Timeout'),
    );

    return result.exitCode == 0;
  }
}
