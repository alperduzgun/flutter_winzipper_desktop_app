import 'package:hive_flutter/hive_flutter.dart';

/// Hive storage keys
enum HiveKeys {
  /// Main storage box
  box('winzipper'),

  /// Recent files
  recentFiles('recent_files'),

  /// App settings
  settings('settings'),

  /// Theme preference
  theme('theme'),

  /// Language preference
  language('language');

  const HiveKeys(this.key);
  final String key;
}

/// Client for Hive local storage
class HiveClient {
  const HiveClient(this._box);

  final Box<dynamic> _box;

  /// Read value from storage
  T? read<T>(HiveKeys key) {
    return _box.get(key.key) as T?;
  }

  /// Write value to storage
  Future<void> write<T>(HiveKeys key, T value) async {
    await _box.put(key.key, value);
  }

  /// Delete value from storage
  Future<void> delete(HiveKeys key) async {
    await _box.delete(key.key);
  }

  /// Check if key exists
  bool contains(HiveKeys key) {
    return _box.containsKey(key.key);
  }

  /// Clear all storage
  Future<void> clear() async {
    await _box.clear();
  }

  /// Get all keys
  Iterable<String> get keys {
    return _box.keys.cast<String>();
  }

  /// Get box length
  int get length => _box.length;
}
