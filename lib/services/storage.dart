import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key–value persistence. On the web this is backed by the
/// browser's localStorage, so data stays on the device.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Iterable<String> keys();
}

class PrefsStore implements KeyValueStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsStore> open() async =>
      PrefsStore(await SharedPreferences.getInstance());

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Iterable<String> keys() => _prefs.getKeys();
}

/// In-memory store for tests.
class MemoryStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);

  @override
  Iterable<String> keys() => data.keys.toList();
}
