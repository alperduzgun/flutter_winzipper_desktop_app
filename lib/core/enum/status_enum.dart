/// Generic status enum for async operations
enum Status {
  /// Initial state
  initial,

  /// Loading/in-progress state
  loading,

  /// Success state
  success,

  /// Error state
  error,
}

/// Extension for Status enum
extension StatusExtension on Status {
  /// Check if status is initial
  bool get isInitial => this == Status.initial;

  /// Check if status is loading
  bool get isLoading => this == Status.loading;

  /// Check if status is success
  bool get isSuccess => this == Status.success;

  /// Check if status is error
  bool get isError => this == Status.error;
}
