/// 登录接口的响应 DTO。
///
/// DTO(Data Transfer Object)只关心**后端 JSON 的形状**:
/// - 字段名保留后端风格(snake_case),不转 camelCase;
/// - 不写业务方法,不引入 Flutter / Riverpod;
/// - 只负责 JSON ↔ Dart 互转。
///
/// 业务实体的转换由 Repository 完成(见 `auth_repository_impl.dart`)。
class LoginResponseDto {
  LoginResponseDto({
    String? avatar,
    String? gender,
    int? birthday,
    int? id,
    String? nickname,
    String? phone,
    String? playstyle,
    int? registerTime,
    String? selfIntroduction,
    String? role,
    String? status,
    String? token,
    String? refreshToken,
  }) {
    _avatar = avatar;
    _gender = gender;
    _birthday = birthday;
    _id = id;
    _nickname = nickname;
    _phone = phone;
    _playstyle = playstyle;
    _registerTime = registerTime;
    _selfIntroduction = selfIntroduction;
    _role = role;
    _status = status;
    _token = token;
    _refreshToken = refreshToken;
  }

  LoginResponseDto.fromJson(dynamic json) {
    _avatar = json['avatar'];
    _gender = json['gender'];
    _birthday = json['birthday'];
    _id = json['id'];
    _nickname = json['nickname'];
    _phone = json['phone'];
    _playstyle = json['playstyle'];
    _registerTime = json['registerTime'];
    _selfIntroduction = json['selfIntroduction'];
    _role = json['role'];
    _status = json['status'];
    _token = json['token'];
    _refreshToken = json['refreshToken'];
  }

  String? _avatar;
  String? _gender;
  int? _birthday;
  int? _id;
  String? _nickname;
  String? _phone;
  String? _playstyle;
  int? _registerTime;
  String? _selfIntroduction;
  String? _role;
  String? _status;
  String? _token;
  String? _refreshToken;

  LoginResponseDto copyWith({
    String? avatar,
    String? gender,
    int? birthday,
    int? id,
    String? nickname,
    String? phone,
    String? playstyle,
    int? registerTime,
    String? selfIntroduction,
    String? role,
    String? status,
    String? token,
    String? refreshToken,
  }) => LoginResponseDto(
    avatar: avatar ?? _avatar,
    gender: gender ?? _gender,
    birthday: birthday ?? _birthday,
    id: id ?? _id,
    nickname: nickname ?? _nickname,
    phone: phone ?? _phone,
    playstyle: playstyle ?? _playstyle,
    registerTime: registerTime ?? _registerTime,
    selfIntroduction: selfIntroduction ?? _selfIntroduction,
    role: role ?? _role,
    status: status ?? _status,
    token: token ?? _token,
    refreshToken: refreshToken ?? _refreshToken,
  );

  String? get avatar => _avatar;

  String? get gender => _gender;

  int? get birthday => _birthday;

  int? get id => _id;

  String? get nickname => _nickname;

  String? get phone => _phone;

  String? get playstyle => _playstyle;

  int? get registerTime => _registerTime;

  String? get selfIntroduction => _selfIntroduction;

  String? get role => _role;

  String? get status => _status;

  String? get token => _token;

  String? get refreshToken => _refreshToken;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['avatar'] = _avatar;
    map['gender'] = _gender;
    map['birthday'] = _birthday;
    map['id'] = _id;
    map['nickname'] = _nickname;
    map['phone'] = _phone;
    map['playstyle'] = _playstyle;
    map['registerTime'] = _registerTime;
    map['selfIntroduction'] = _selfIntroduction;
    map['role'] = _role;
    map['status'] = _status;
    map['token'] = _token;
    map['refreshToken'] = _refreshToken;
    return map;
  }

  @override
  String toString() {
    return 'User{avatar: $_avatar, gender: $_gender, birthday: $_birthday, id: $_id, nickname: $_nickname, phone: $_phone, playstyle: $_playstyle, registerTime: $_registerTime, selfIntroduction: $_selfIntroduction, role: $_role, status: $_status, token: $_token, refreshToken: $_refreshToken}';
  }
}
