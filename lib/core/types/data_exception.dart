import 'package:equatable/equatable.dart';

/// Custom error class for handling exceptions across the app
class Err extends Equatable implements Exception {
  const Err(
    this.error, [
    this.stackTrace,
  ]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return error.toString();
  }

  @override
  List<Object?> get props => [error, stackTrace];
}

/// Extension for error handling
extension ErrExtension on Object {
  /// Convert any error to Err type
  Err toErr([StackTrace? stackTrace]) {
    return Err(this, stackTrace);
  }
}
