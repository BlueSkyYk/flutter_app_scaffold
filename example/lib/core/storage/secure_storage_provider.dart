import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 跨业务域共享的安全存储 Provider。
///
/// 脚手架不内置 secure storage(涉及 Android minSdkVersion / iOS Keychain
/// entitlement,见包级 README),由业务工程在 core 层统一暴露。
/// auth、profile、payment 等多个 feature 都可以 ref.read(secureStorageProvider) 复用。
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
