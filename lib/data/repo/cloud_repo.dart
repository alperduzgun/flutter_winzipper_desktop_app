import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_pkg;
import '../../core/types/typedefs.dart';
import '../dto/cloud/req_upload_dto.dart';
import '../path/cloud_path.dart';

/// Repository interface for cloud operations
abstract class ICloudRepo {
  /// Upload file to cloud storage
  Future<String> uploadFile(
    ReqUploadDto dto, {
    Function(double progress)? onProgress,
  });
}

/// Implementation of cloud repository using HTTP client
class CloudRepo implements ICloudRepo {
  static const Duration _timeout = Duration(minutes: 10);
  static const int _maxRetries = 3;
  static const int _maxFileSizeBytes = 1 * 1024 * 1024 * 1024; // 1GB

  @override
  Future<String> uploadFile(
    ReqUploadDto dto, {
    Function(double progress)? onProgress,
  }) async {
    int retries = 0;

    while (retries < _maxRetries) {
      try {
        return await _attemptUpload(dto, onProgress);
      } on SocketException catch (e) {
        retries++;
        if (retries >= _maxRetries) {
          throw _createConnectionError(e);
        }
        // Exponential backoff: 2s, 4s, 8s
        await Future.delayed(Duration(seconds: 2 << (retries - 1)));
      } on TimeoutException {
        throw Exception('Upload timeout (exceeded 10 minutes)');
      } on HttpException catch (e) {
        throw _createHttpError(e);
      }
    }

    throw Exception('Upload failed after $_maxRetries retries');
  }

  Future<String> _attemptUpload(
    ReqUploadDto dto,
    Function(double progress)? onProgress,
  ) async {
    final file = File(dto.filePath);

    // Validate file
    if (!await file.exists()) {
      throw Exception('File not found');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('File is empty');
    }

    if (fileSize > _maxFileSizeBytes) {
      final sizeStr = _formatFileSize(fileSize);
      throw Exception('File too large ($sizeStr). Max: 1GB for free uploads');
    }

    // Create multipart request
    final uri = Uri.parse(CloudPath.litterboxUpload.path);
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['User-Agent'] = 'WinZipper/${Platform.operatingSystem}';
    request.headers['Accept'] = '*/*';

    // Add form fields
    request.fields['reqtype'] = 'fileupload';
    request.fields['time'] = dto.retentionTime;

    // Add file with progress tracking
    int bytesRead = 0;
    final stream = file.openRead();

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
        handleDone: (EventSink<List<int>> sink) => sink.close(),
        handleError: (error, stackTrace, EventSink<List<int>> sink) {
          sink.addError(error, stackTrace);
        },
      ),
    );

    final multipartFile = http.MultipartFile(
      'fileToUpload',
      progressStream,
      fileSize,
      filename: dto.fileName,
    );

    request.files.add(multipartFile);

    // Send request
    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    // Handle response
    return _handleResponse(response, streamedResponse.statusCode);
  }

  String _handleResponse(http.Response response, int statusCode) {
    if (statusCode == 200) {
      final downloadUrl = response.body.trim();

      // Validate URL
      if (downloadUrl.isNotEmpty &&
          downloadUrl.startsWith('http') &&
          !downloadUrl.contains('<html>') &&
          !downloadUrl.toLowerCase().contains('error') &&
          !downloadUrl.toLowerCase().contains('access denied')) {
        return downloadUrl;
      } else {
        throw Exception(
          'Upload rejected: ${downloadUrl.isEmpty ? "No response" : downloadUrl}',
        );
      }
    } else if (statusCode == 403) {
      throw Exception(
        'Access denied by server.\n'
        'Possible causes:\n'
        '• Service is blocking uploads\n'
        '• Cloudflare protection active\n'
        '• Try again later',
      );
    } else if (statusCode == 429) {
      throw SocketException('Rate limit exceeded');
    } else if (statusCode >= 500) {
      throw SocketException('Server error: $statusCode');
    } else {
      throw Exception('Upload failed: $statusCode ${response.reasonPhrase}');
    }
  }

  Exception _createConnectionError(SocketException e) {
    if (e.message.contains('Connection refused') ||
        e.osError?.errorCode == 61 || // macOS
        e.osError?.errorCode == 111) {
      // Linux
      return Exception(
        'Cannot connect to upload service.\n'
        'Please check:\n'
        '• Internet connection\n'
        '• Firewall settings\n'
        '• VPN configuration',
      );
    }
    return Exception('Network error: ${e.message}');
  }

  Exception _createHttpError(HttpException e) {
    if (e.message.contains('Connection refused') ||
        e.message.contains('Failed host lookup')) {
      return Exception(
        'Cannot connect to upload service.\n'
        'Please check:\n'
        '• Internet connection\n'
        '• Firewall settings\n'
        '• VPN configuration',
      );
    }
    return Exception('Network error: ${e.message}');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
