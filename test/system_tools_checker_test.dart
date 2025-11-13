import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:winzipper/utils/system_tools_checker.dart';

void main() {
  group('SystemToolsChecker', () {
    group('getInstallationInstructions', () {
      test('should provide instructions for unrar on macOS', () {
        final instructions =
            SystemToolsChecker.getInstallationInstructions('unrar');
        expect(instructions, contains('brew install'));
        expect(instructions, contains('unrar'));
      });

      test('should provide instructions for 7z', () {
        final instructions =
            SystemToolsChecker.getInstallationInstructions('7z');
        expect(instructions, isNotEmpty);
        expect(instructions.toLowerCase(), contains('7z').or(contains('p7zip')));
      });

      test('should provide instructions for rar', () {
        final instructions =
            SystemToolsChecker.getInstallationInstructions('rar');
        expect(instructions, isNotEmpty);
      });
    });

    group('getToolErrorMessage', () {
      test('should include tool name in error message', () {
        final message = SystemToolsChecker.getToolErrorMessage('unrar');
        expect(message.toLowerCase(), contains('unrar'));
      });

      test('should include installation instructions', () {
        final message = SystemToolsChecker.getToolErrorMessage('7z');
        expect(message, isNotEmpty);
        expect(message.length, greaterThan(20));
      });
    });

    group('canHandleArchiveType', () {
      test('should return true for natively supported formats', () async {
        expect(await SystemToolsChecker.canHandleArchiveType('zip'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('tar'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('gz'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('gzip'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('bz2'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('bzip2'), isTrue);
      });

      test('should return false for unknown formats', () async {
        expect(
            await SystemToolsChecker.canHandleArchiveType('unknown'), isFalse);
        expect(await SystemToolsChecker.canHandleArchiveType('txt'), isFalse);
      });

      test('should be case-insensitive', () async {
        expect(await SystemToolsChecker.canHandleArchiveType('ZIP'), isTrue);
        expect(await SystemToolsChecker.canHandleArchiveType('TAR'), isTrue);
      });
    });
  });
}
