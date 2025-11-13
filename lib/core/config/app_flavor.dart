import 'api_options.dart';

/// Flavor types for the application
enum FlavorType {
  /// Development flavor
  development,

  /// Staging flavor
  staging,

  /// Production flavor
  production,
}

/// App flavor configuration
class AppFlavor {
  /// Factory constructor for creating flavor instance
  factory AppFlavor({
    required String name,
    required FlavorType flavorType,
    required ApiOptions apiOptions,
  }) {
    _instance = AppFlavor._internal(
      name,
      flavorType,
      apiOptions,
    );
    return _instance!;
  }

  /// Factory constructor for getting current instance
  factory AppFlavor.instance() {
    if (_instance == null) {
      throw StateError('AppFlavor not initialized. Call AppFlavor() first.');
    }
    return _instance!;
  }

  AppFlavor._internal(
    this.name,
    this.flavorType,
    this.apiOptions,
  );

  static AppFlavor? _instance;

  /// Flavor name (e.g., "WinZipper [DEV]")
  final String name;

  /// Flavor type
  final FlavorType flavorType;

  /// API configuration for this flavor
  final ApiOptions apiOptions;

  /// Check if current flavor is development
  bool get isDevelopment => flavorType == FlavorType.development;

  /// Check if current flavor is staging
  bool get isStaging => flavorType == FlavorType.staging;

  /// Check if current flavor is production
  bool get isProduction => flavorType == FlavorType.production;
}
