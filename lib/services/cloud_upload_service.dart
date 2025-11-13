import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Result of cloud upload operation
class UploadResult {
  final bool success;
  final String? url;
  final String? error;

  UploadResult.success(this.url)
      : success = true,
        error = null;

  UploadResult.failure(this.error)
      : success = false,
        url = null;
}

/// Service for uploading files to cloud storage
/// Uses transfer.sh free upload service
class CloudUploadService {
  static const String _uploadUrl = 'https://transfer.sh';
  static const Duration _timeout = Duration(minutes: 5);

  /// Upload a file to transfer.sh and get shareable link
  ///
  /// [filePath] - Path to file to upload
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns [UploadResult] with success status and URL or error
  Future<UploadResult> uploadFile(
    String filePath, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return UploadResult.failure('File not found');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return UploadResult.failure('File is empty');
      }

      // Check file size (transfer.sh has limits, reasonable check)
      if (fileSize > 10 * 1024 * 1024 * 1024) { // 10GB
        return UploadResult.failure('File too large (max 10GB)');
      }

      final fileName = path.basename(filePath);
      final uri = Uri.parse('$_uploadUrl/$fileName');

      // Create multipart request
      final request = http.MultipartRequest('PUT', uri);

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileSize,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send request with timeout and progress tracking
      final streamedResponse = await request.send().timeout(_timeout);

      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        final downloadUrl = response.body.trim();

        if (downloadUrl.isNotEmpty && downloadUrl.startsWith('http')) {
          return UploadResult.success(downloadUrl);
        } else {
          return UploadResult.failure('Invalid response from server');
        }
      } else {
        return UploadResult.failure(
          'Upload failed: ${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}',
        );
      }
    } on TimeoutException {
      return UploadResult.failure('Upload timeout (exceeded 5 minutes)');
    } on SocketException {
      return UploadResult.failure('Network error: No internet connection');
    } catch (e) {
      return UploadResult.failure('Upload error: ${e.toString()}');
    }
  }

  /// Get file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
