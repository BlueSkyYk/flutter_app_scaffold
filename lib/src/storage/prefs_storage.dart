import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kv_storage.dart';

/// 基于 shared_preferences 的 KV 存储实现。
class PrefsStorage implements KvStorage {
  PrefsStorage._(this._prefs);

  final SharedPreferences _prefs;

  static PrefsStorage? _instance;

  static Future<PrefsStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return _instance ??= PrefsStorage._(prefs);
  }

  static PrefsStorage get I {
    final ins = _instance;
    if (ins == null) {
      throw StateError('PrefsStorage 未初始化，请先 await PrefsStorage.init()');
    }
    return ins;
  }

  /// 清除已初始化的实例。仅用于测试隔离，正式代码不要调用。
  @visibleForTesting
  static void reset() => _instance = null;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      _prefs.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);
}
