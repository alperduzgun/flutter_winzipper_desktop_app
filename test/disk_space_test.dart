import 'package:flutter_test/flutter_test.dart';
import 'package:winzipper/utils/system_tools_checker.dart';
import 'dart:io';

void main() {
  group('SystemToolsChecker - Disk Space', () {
    test('getAvailableDiskSpace should return positive value', () async {
      final tempDir = Directory.systemTemp.createTempSync('test_disk_space');
      try {
        final space = await SystemToolsChecker.getAvailableDiskSpace(tempDir.path);
        expect(space, greaterThan(0));
        expect(space, lessThan(1000 * 1024 * 1024 * 1024 * 1024)); // Less than 1000TB
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getAvailableDiskSpace should handle non-existent path gracefully', () async {
      final space = await SystemToolsChecker.getAvailableDiskSpace('/nonexistent/path/test');
      // Should return fallback value
      expect(space, greaterThan(0));
    });
  });
}
