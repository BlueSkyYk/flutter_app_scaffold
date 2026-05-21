import 'package:example/features/auth/data/dto/login_response_dto.dart';

/// 登录后的用户实体。
///
/// 纯 Dart 类,不依赖 Flutter / Riverpod / Dio —— 这是 domain 层的硬约束:
/// 任何业务实体都应该能被单元测试单独实例化、不需要 mock 任何框架。
///
/// 如果将来这个实体被多个无关业务域共享(profile / order / social 都要用),
/// 应该提到 core/domain/ 或独立成 user/ 域,而不是各自定义同名类。

/// avatar : ""
/// birthday : 3432523523423
/// id : 2011645072596279297
/// nickname : "张三"
/// phone : "19900000000"
/// playstyle : ""
/// registerTime : 1768448535000
/// selfIntroduction : ""
/// status : "NORMAL"
/// token : "ca824a61-21b8-4abd-b3f4-a3afe3daf96d"

class AuthUser {
  AuthUser({
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

  AuthUser.fromDto(LoginResponseDto dto)
    : this(
        avatar: dto.avatar,
        gender: dto.gender,
        birthday: dto.birthday,
        id: dto.id,
        nickname: dto.nickname,
        phone: dto.phone,
        playstyle: dto.playstyle,
        registerTime: dto.registerTime,
        selfIntroduction: dto.selfIntroduction,
        role: dto.role,
        status: dto.status,
        token: dto.token,
        refreshToken: dto.refreshToken,
      );

  AuthUser.fromJson(dynamic json) {
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

  AuthUser copyWith({
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
  }) => AuthUser(
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
