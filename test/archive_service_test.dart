import 'package:flutter_test/flutter_test.dart';
import 'package:winzipper/services/archive_service.dart';

void main() {
  group('ArchiveService', () {
    group('detectArchiveType', () {
      test('should detect ZIP archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.zip'),
          ArchiveType.zip,
        );
        expect(
          ArchiveService.detectArchiveType('myfile.ZIP'),
          ArchiveType.zip,
        );
      });

      test('should detect RAR archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.rar'),
          ArchiveType.rar,
        );
      });

      test('should detect 7-Zip archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.7z'),
          ArchiveType.sevenZip,
        );
      });

      test('should detect TAR archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.tar'),
          ArchiveType.tar,
        );
      });

      test('should detect GZIP archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.gz'),
          ArchiveType.gzip,
        );
        expect(
          ArchiveService.detectArchiveType('test.gzip'),
          ArchiveType.gzip,
        );
      });

      test('should detect BZIP2 archives correctly', () {
        expect(
          ArchiveService.detectArchiveType('test.bz2'),
          ArchiveType.bzip2,
        );
        expect(
          ArchiveService.detectArchiveType('test.bzip2'),
          ArchiveType.bzip2,
        );
      });

      test('should return unknown for unsupported file types', () {
        expect(
          ArchiveService.detectArchiveType('test.txt'),
          ArchiveType.unknown,
        );
        expect(
          ArchiveService.detectArchiveType('document.pdf'),
          ArchiveType.unknown,
        );
      });

      test('should handle files without extension', () {
        expect(
          ArchiveService.detectArchiveType('noextension'),
          ArchiveType.unknown,
        );
      });

      test('should be case-insensitive', () {
        expect(
          ArchiveService.detectArchiveType('TEST.ZIP'),
          ArchiveType.zip,
        );
        expect(
          ArchiveService.detectArchiveType('Test.Rar'),
          ArchiveType.rar,
        );
      });
    });
  });
}
