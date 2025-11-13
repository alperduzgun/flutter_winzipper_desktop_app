import 'package:dio/dio.dart';
import '../../config/api_options.dart';
import '../../config/app_flavor.dart';
import '../../types/typedefs.dart';

/// HTTP client for making API requests
class HttpClient {
  HttpClient() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  late final Dio _dio;

  BaseOptions get _baseOptions {
    final apiOptions = AppFlavor.instance().apiOptions;
    return BaseOptions(
      baseUrl: apiOptions.baseUrl,
      connectTimeout: apiOptions.timeout,
      receiveTimeout: apiOptions.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token if needed
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          // Handle errors globally
          return handler.next(error);
        },
      ),
    );

    // Add logging in development
    if (AppFlavor.instance().isDevelopment) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// GET request returning Map
  Future<Response<Map<String, dynamic>>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return get<Map<String, dynamic>>(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request returning Map
  Future<Response<Map<String, dynamic>>> postMap(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  /// POST multipart request (for file uploads)
  Future<Response<T>> postMultipart<T>(
    String url, {
    required Map<String, String> files,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();

    // Add files
    for (final entry in files.entries) {
      formData.files.add(
        MapEntry(
          entry.key,
          await MultipartFile.fromFile(entry.value),
        ),
      );
    }

    // Add other data
    if (data != null) {
      for (final entry in data.entries) {
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    return _dio.post<T>(
      url,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'WinZipper/1.0',
        },
        sendTimeout: AppFlavor.instance().apiOptions.uploadTimeout,
      ),
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
