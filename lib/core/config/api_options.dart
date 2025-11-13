import '../config/app_constant.dart';

/// API configuration options
class ApiOptions {
  const ApiOptions({
    required this.baseUrl,
    required this.cloudUploadUrl,
    this.timeout = AppConstant.defaultTimeout,
    this.uploadTimeout = AppConstant.uploadTimeout,
  });

  /// Development API options
  factory ApiOptions.development() {
    return const ApiOptions(
      baseUrl: 'http://localhost:3000',
      cloudUploadUrl:
          'https://litterbox.catbox.moe/resources/internals/api.php',
    );
  }

  /// Staging API options
  factory ApiOptions.staging() {
    return const ApiOptions(
      baseUrl: 'https://staging-api.winzipper.com',
      cloudUploadUrl:
          'https://litterbox.catbox.moe/resources/internals/api.php',
    );
  }

  /// Production API options
  factory ApiOptions.production() {
    return const ApiOptions(
      baseUrl: 'https://api.winzipper.com',
      cloudUploadUrl:
          'https://litterbox.catbox.moe/resources/internals/api.php',
    );
  }

  /// Base API URL
  final String baseUrl;

  /// Cloud upload service URL
  final String cloudUploadUrl;

  /// Default request timeout
  final Duration timeout;

  /// Upload request timeout
  final Duration uploadTimeout;
}
