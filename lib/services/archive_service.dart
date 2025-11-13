import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

enum ArchiveType { zip, tar, gzip, bzip2, sevenZip, rar, unknown }

class ArchiveService {
  /// Detects the archive type based on file extension
  static ArchiveType detectArchiveType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
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

  /// Extracts an archive to the specified destination
  static Future<bool> extractArchive(
    String archivePath,
    String destinationPath,
  ) async {
    try {
      final archiveType = detectArchiveType(archivePath);
      final bytes = await File(archivePath).readAsBytes();

      Archive? archive;

      switch (archiveType) {
        case ArchiveType.zip:
          archive = ZipDecoder().decodeBytes(bytes);
          break;
        case ArchiveType.tar:
          archive = TarDecoder().decodeBytes(bytes);
          break;
        case ArchiveType.gzip:
          final decompressed = GZipDecoder().decodeBytes(bytes);
          // Check if it's a tar.gz
          final fileName = path.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            // Single file gzip
            final outputFile = File(path.join(destinationPath, fileName));
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(decompressed);
            return true;
          }
          break;
        case ArchiveType.bzip2:
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          final fileName = path.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            final outputFile = File(path.join(destinationPath, fileName));
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(decompressed);
            return true;
          }
          break;
        case ArchiveType.sevenZip:
        case ArchiveType.rar:
          // For 7z and RAR, we need to use platform-specific tools
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
      print('Error extracting archive: $e');
      return false;
    }
  }

  /// Extracts archive contents to directory
  static Future<void> _extractArchiveToDirectory(
    Archive archive,
    String destinationPath,
  ) async {
    for (final file in archive) {
      final filename = path.join(destinationPath, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }
  }

  /// Extracts using system tools (for 7z and RAR on macOS)
  static Future<bool> _extractUsingSystemTools(
    String archivePath,
    String destinationPath,
    ArchiveType type,
  ) async {
    try {
      if (!Platform.isMacOS && !Platform.isLinux) {
        throw Exception('System tools extraction only supported on macOS/Linux');
      }

      String command;
      List<String> args;

      if (type == ArchiveType.sevenZip) {
        // Use 7z command if available
        command = '7z';
        args = ['x', archivePath, '-o$destinationPath', '-y'];
      } else if (type == ArchiveType.rar) {
        // Use unrar command if available
        command = 'unrar';
        args = ['x', '-o+', archivePath, destinationPath];
      } else {
        return false;
      }

      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } catch (e) {
      print('Error using system tools: $e');
      return false;
    }
  }

  /// Compresses files/folder into an archive
  static Future<bool> compressToArchive(
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
          break;
        case ArchiveType.tar:
          encodedData = TarEncoder().encode(archive);
          break;
        case ArchiveType.gzip:
          // For gzip, we need to tar first if multiple files
          if (sourcePaths.length > 1 ||
              FileSystemEntity.typeSync(sourcePaths[0]) ==
                  FileSystemEntityType.directory) {
            final tarData = TarEncoder().encode(archive);
            encodedData = GZipEncoder().encode(tarData);
          } else {
            final fileBytes = await File(sourcePaths[0]).readAsBytes();
            encodedData = GZipEncoder().encode(fileBytes);
          }
          break;
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
          break;
        case ArchiveType.sevenZip:
        case ArchiveType.rar:
          // Use system tools for 7z and RAR compression
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
      print('Error compressing archive: $e');
      return false;
    }
  }

  /// Adds a file to the archive
  static Future<void> _addFileToArchive(Archive archive, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archiveFile = ArchiveFile(path.basename(filePath), bytes.length, bytes);
    archive.addFile(archiveFile);
  }

  /// Adds a directory and its contents to the archive recursively
  static Future<void> _addDirectoryToArchive(
    Archive archive,
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);
    final baseDir = path.basename(directoryPath);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final relativePath = path.relative(entity.path, from: directoryPath);
        final archivePath = path.join(baseDir, relativePath);
        final archiveFile = ArchiveFile(archivePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      }
    }
  }

  /// Compresses using system tools (for 7z and RAR on macOS)
  static Future<bool> _compressUsingSystemTools(
    List<String> sourcePaths,
    String destinationArchivePath,
    ArchiveType type,
  ) async {
    try {
      if (!Platform.isMacOS && !Platform.isLinux) {
        throw Exception('System tools compression only supported on macOS/Linux');
      }

      String command;
      List<String> args;

      if (type == ArchiveType.sevenZip) {
        command = '7z';
        args = ['a', destinationArchivePath, ...sourcePaths];
      } else if (type == ArchiveType.rar) {
        command = 'rar';
        args = ['a', destinationArchivePath, ...sourcePaths];
      } else {
        return false;
      }

      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } catch (e) {
      print('Error using system tools for compression: $e');
      return false;
    }
  }

  /// Lists the contents of an archive
  static Future<List<String>> listArchiveContents(String archivePath) async {
    try {
      final archiveType = detectArchiveType(archivePath);
      final bytes = await File(archivePath).readAsBytes();

      Archive? archive;

      switch (archiveType) {
        case ArchiveType.zip:
          archive = ZipDecoder().decodeBytes(bytes);
          break;
        case ArchiveType.tar:
          archive = TarDecoder().decodeBytes(bytes);
          break;
        case ArchiveType.gzip:
          final decompressed = GZipDecoder().decodeBytes(bytes);
          final fileName = path.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            return [fileName];
          }
          break;
        case ArchiveType.bzip2:
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          final fileName = path.basenameWithoutExtension(archivePath);
          if (fileName.endsWith('.tar')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            return [fileName];
          }
          break;
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
      print('Error listing archive contents: $e');
      return [];
    }
  }

  /// Lists archive contents using system tools
  static Future<List<String>> _listUsingSystemTools(
    String archivePath,
    ArchiveType type,
  ) async {
    try {
      String command;
      List<String> args;

      if (type == ArchiveType.sevenZip) {
        command = '7z';
        args = ['l', archivePath];
      } else if (type == ArchiveType.rar) {
        command = 'unrar';
        args = ['l', archivePath];
      } else {
        return [];
      }

      final result = await Process.run(command, args);
      if (result.exitCode == 0) {
        // Parse the output to extract file names
        final lines = result.stdout.toString().split('\n');
        return lines
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .toList();
      }
      return [];
    } catch (e) {
      print('Error listing using system tools: $e');
      return [];
    }
  }
}
