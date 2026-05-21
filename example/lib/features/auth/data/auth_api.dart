import 'package:example/core/network/http_parser.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../../../core/network/dio_provider.dart';
import 'dto/login_response_dto.dart';

/// auth 域的 HTTP 端点集合(data 层内部)。
///
/// 职责:把"业务方法名 + 参数"翻译成 HTTP 请求,把响应解码成 DTO。
/// 不做:错误转换 / 缓存 / 业务规则 —— 那些是 Repository 的职责。
///
/// 当前所有方法都是 **本地 mock**(用 Future.delayed 模拟网络延迟),
/// 真实接后端时,按每个方法体里的注释把 mock 块替换成 _dio.post/get 即可,
/// **方法签名和返回类型不用变**,Repository / Controller / UI 也不用动。
class AuthApi {
  AuthApi(this._dio);

  // ignore: unused_field
  final DioClient _dio;

  /// 登录。
  ///
  /// 真实接口示例:
  /// ```
  /// final res = await _dio.post<Map<String, dynamic>>(
  ///   '/auth/login',
  ///   data: {'username': username, 'password': password},
  /// );
  /// return LoginResponseDto.fromJson(res.data!);
  /// ```
  Future<LoginResponseDto> login({
    required String phone,
    required String code,
  }) async {
    AppLog.i('[auth-api] POST /auth/login (mock)');
    final res = await _dio.post(
      "/user/login",
      data: {"phone": phone, "code": code},
    );
    return parseModel(response: res, parser: LoginResponseDto.fromJson);
  }

  /// 登出。
  ///
  /// 真实接口示例:`await _dio.post<void>('/auth/logout');`
  Future<void> logout() async {
    AppLog.i('[auth-api] POST /auth/logout (mock)');
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(dioProvider));
});
