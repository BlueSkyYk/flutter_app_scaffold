import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储（token、密钥等敏感数据）。iOS 走 Keychain，Android 走 EncryptedSharedPreferences。
class SecureStorage {
  SecureStorage._();

  static final SecureStorage I = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
