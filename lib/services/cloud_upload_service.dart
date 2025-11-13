import 'dart:async';
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
/// Uses Litterbox (catbox.moe) - free temporary file hosting
/// Files are kept for 72 hours (3 days)
class CloudUploadService {
  static const String _uploadUrl = 'https://litterbox.catbox.moe/resources/internals/api.php';
  static const Duration _timeout = Duration(minutes: 10);
  static const int _maxRetries = 3;

  /// Upload a file to Litterbox and get shareable link (72h retention)
  ///
  /// [filePath] - Path to file to upload
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns [UploadResult] with success status and URL or error
  Future<UploadResult> uploadFile(
    String filePath, {
    Function(double progress)? onProgress,
  }) async {
    int retries = 0;

    while (retries < _maxRetries) {
      try {
        final result = await _attemptUpload(filePath, onProgress);
        return result;
      } on SocketException catch (e) {
        retries++;
        if (retries >= _maxRetries) {
          // Provide user-friendly error message
          if (e.message.contains('Connection refused') ||
              e.osError?.errorCode == 61 || // macOS connection refused
              e.osError?.errorCode == 111) {  // Linux connection refused
            return UploadResult.failure(
              'Cannot connect to upload service.\n'
              'Please check:\n'
              '• Internet connection\n'
              '• Firewall settings\n'
              '• VPN configuration',
            );
          }
          return UploadResult.failure('Network error: ${e.message}');
        }
        // Exponential backoff: 2s, 4s, 8s
        await Future.delayed(Duration(seconds: 2 << (retries - 1)));
      } on TimeoutException {
        return UploadResult.failure('Upload timeout (exceeded 10 minutes)');
      } on HttpException catch (e) {
        // HTTP exceptions (like connection issues)
        if (e.message.contains('Connection refused') ||
            e.message.contains('Failed host lookup')) {
          return UploadResult.failure(
            'Cannot connect to upload service.\n'
            'Please check:\n'
            '• Internet connection\n'
            '• Firewall settings\n'
            '• VPN configuration',
          );
        }
        return UploadResult.failure('Network error: ${e.message}');
      } catch (e) {
        return UploadResult.failure('Upload error: ${e.toString()}');
      }
    }

    return UploadResult.failure('Upload failed after $_maxRetries retries');
  }

  /// Single upload attempt
  Future<UploadResult> _attemptUpload(
    String filePath,
    Function(double progress)? onProgress,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return UploadResult.failure('File not found');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      return UploadResult.failure('File is empty');
    }

    // Litterbox doesn't specify size limit, but reasonable limit for free service
    if (fileSize > 1 * 1024 * 1024 * 1024) {
      return UploadResult.failure(
        'File too large (${formatFileSize(fileSize)}). Max: 1GB',
      );
    }

    final fileName = path.basename(filePath);

    // Litterbox uses multipart form data
    final uri = Uri.parse(_uploadUrl);
    final request = http.MultipartRequest('POST', uri);

    // Add form fields
    request.fields['reqtype'] = 'fileupload';
    request.fields['time'] = '72h'; // Keep file for 72 hours (3 days)

    // Add file with stream to avoid loading entire file into memory
    int bytesRead = 0;
    final stream = file.openRead();

    // Track progress with stream transformer
    final progressStream = stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          bytesRead += data.length;
          if (onProgress != null) {
            final progress = bytesRead / fileSize;
            onProgress(progress);
          }
          sink.add(data);
        },
        handleDone: (EventSink<List<int>> sink) {
          sink.close();
        },
        handleError: (error, stackTrace, EventSink<List<int>> sink) {
          sink.addError(error, stackTrace);
        },
      ),
    );

    // Create multipart file from stream
    final multipartFile = http.MultipartFile(
      'fileToUpload',
      progressStream,
      fileSize,
      filename: fileName,
    );

    request.files.add(multipartFile);

    // Send request
    final streamedResponse = await request.send().timeout(_timeout);

    // Read response
    final response = await http.Response.fromStream(streamedResponse);

    if (streamedResponse.statusCode == 200) {
      final downloadUrl = response.body.trim();

      // Validate response (Litterbox returns just the URL)
      if (downloadUrl.isNotEmpty &&
          downloadUrl.startsWith('http') &&
          !downloadUrl.contains('<html>') &&
          !downloadUrl.contains('error')) {
        return UploadResult.success(downloadUrl);
      } else {
        return UploadResult.failure('Invalid response from server');
      }
    } else if (streamedResponse.statusCode == 429) {
      // Rate limit - will retry with backoff
      throw SocketException('Rate limit exceeded');
    } else if (streamedResponse.statusCode >= 500) {
      // Server error - will retry
      throw SocketException('Server error: ${streamedResponse.statusCode}');
    } else {
      return UploadResult.failure(
        'Upload failed: ${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}',
      );
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
