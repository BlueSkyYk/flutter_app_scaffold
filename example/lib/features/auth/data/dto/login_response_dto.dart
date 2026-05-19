/// 登录接口的响应 DTO。
///
/// DTO(Data Transfer Object)只关心**后端 JSON 的形状**:
/// - 字段名保留后端风格(snake_case),不转 camelCase;
/// - 不写业务方法,不引入 Flutter / Riverpod;
/// - 只负责 JSON ↔ Dart 互转。
///
/// 业务实体的转换由 Repository 完成(见 `auth_repository_impl.dart`)。
class LoginResponseDto {
  const LoginResponseDto({
    required this.userId,
    required this.username,
    required this.accessToken,
    this.refreshToken,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  final String userId;
  final String username;
  final String accessToken;
  final String? refreshToken;
}
