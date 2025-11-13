import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'data_exception.dart';

/// Type alias for asynchronous operations that return Either (Err or result)
typedef AsyncRes<T> = Future<Either<Err, T>>;

/// Type alias for HTTP responses with Map data
typedef AsyncResMap = Future<Response<Map<String, dynamic>>>;

/// Type alias for JSON maps
typedef JSON = Map<String, dynamic>;

/// Type alias for nullable JSON maps
typedef JSONOrNull = Map<String, dynamic>?;
