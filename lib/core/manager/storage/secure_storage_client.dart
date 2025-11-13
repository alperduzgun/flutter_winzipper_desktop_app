import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage keys
enum SecureKeys {
  /// Authentication token
  token,

  /// User credentials
  credentials,

  /// API key
  apiKey;
}

/// Client for secure storage (encrypted)
class SecureStorageClient {
  const SecureStorageClient(this._storage);

  final FlutterSecureStorage _storage;

  /// Read value from secure storage
  Future<String?> read(SecureKeys key) async {
    return _storage.read(key: key.name);
  }

  /// Write value to secure storage
  Future<void> write(SecureKeys key, String value) async {
    await _storage.write(key: key.name, value: value);
  }

  /// Delete value from secure storage
  Future<void> delete(SecureKeys key) async {
    await _storage.delete(key: key.name);
  }

  /// Check if key exists
  Future<bool> contains(SecureKeys key) async {
    final value = await read(key);
    return value != null;
  }

  /// Clear all secure storage
  Future<void> clear() async {
    await _storage.deleteAll();
  }

  /// Get all keys
  Future<Map<String, String>> getAll() async {
    return _storage.readAll();
  }
}
