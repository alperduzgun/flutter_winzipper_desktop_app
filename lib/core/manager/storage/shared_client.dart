import 'package:shared_preferences/shared_preferences.dart';

/// Shared preferences keys
enum SharedKeys {
  /// Theme mode (light/dark)
  themeMode,

  /// Language code
  languageCode,

  /// First launch flag
  isFirstLaunch,

  /// Recent files list
  recentFiles,

  /// Last used compression level
  compressionLevel,

  /// Last used format
  lastFormat;
}

/// Client for shared preferences (simple key-value storage)
class SharedClient {
  const SharedClient(this._prefs);

  final SharedPreferences _prefs;

  /// Read string value
  String? readString(SharedKeys key) {
    return _prefs.getString(key.name);
  }

  /// Write string value
  Future<bool> writeString(SharedKeys key, String value) async {
    return _prefs.setString(key.name, value);
  }

  /// Read int value
  int? readInt(SharedKeys key) {
    return _prefs.getInt(key.name);
  }

  /// Write int value
  Future<bool> writeInt(SharedKeys key, int value) async {
    return _prefs.setInt(key.name, value);
  }

  /// Read bool value
  bool? readBool(SharedKeys key) {
    return _prefs.getBool(key.name);
  }

  /// Write bool value
  Future<bool> writeBool(SharedKeys key, bool value) async {
    return _prefs.setBool(key.name, value);
  }

  /// Read double value
  double? readDouble(SharedKeys key) {
    return _prefs.getDouble(key.name);
  }

  /// Write double value
  Future<bool> writeDouble(SharedKeys key, double value) async {
    return _prefs.setDouble(key.name, value);
  }

  /// Read string list
  List<String>? readStringList(SharedKeys key) {
    return _prefs.getStringList(key.name);
  }

  /// Write string list
  Future<bool> writeStringList(SharedKeys key, List<String> value) async {
    return _prefs.setStringList(key.name, value);
  }

  /// Delete value
  Future<bool> delete(SharedKeys key) async {
    return _prefs.remove(key.name);
  }

  /// Check if key exists
  bool contains(SharedKeys key) {
    return _prefs.containsKey(key.name);
  }

  /// Clear all preferences
  Future<bool> clear() async {
    return _prefs.clear();
  }

  /// Get all keys
  Set<String> get keys => _prefs.getKeys();
}
