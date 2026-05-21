/// 动态接口的响应 DTO。
///
/// DTO 只关心**后端 JSON 的形状**,字段名沿用后端风格;
/// JSON ↔ Dart 互转写在这里,domain 实体的转换交给 Repository。
class FeedItemDto {
  FeedItemDto({
    int? id,
    int? userId,
    String? userNickname,
    String? userAvatar,
    String? content,
    String? contentType,
    List<String>? imageUrls,
    String? videoUrl,
    List<String>? tags,
    bool? visible,
    int? likeCount,
    int? commentCount,
    bool? liked,
    String? createdAt,
  }) {
    _id = id;
    _userId = userId;
    _userNickname = userNickname;
    _userAvatar = userAvatar;
    _content = content;
    _contentType = contentType;
    _imageUrls = imageUrls ?? [];
    _videoUrl = videoUrl;
    _tags = tags ?? [];
    _visible = visible ?? true;
    _likeCount = likeCount ?? 0;
    _commentCount = commentCount ?? 0;
    _liked = liked ?? false;
    _createdAt = createdAt;
  }

  FeedItemDto.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['userId'];
    _userNickname = json['userNickname'];
    _userAvatar = json['userAvatar'];
    _content = json['content'];
    _contentType = json['contentType'];
    _imageUrls = json['imageUrls'] != null
        ? List<String>.from(json['imageUrls'])
        : [];
    _videoUrl = json['videoUrl'];
    _tags = json['tags'] != null ? List<String>.from(json['tags']) : [];
    _visible = json['visible'] ?? true;
    _likeCount = json['likeCount'] ?? 0;
    _commentCount = json['commentCount'] ?? 0;
    _liked = json['liked'] ?? false;
    _createdAt = json['createdAt'];
  }

  int? _id;
  int? _userId;
  String? _userNickname;
  String? _userAvatar;
  String? _content;
  String? _contentType;
  List<String> _imageUrls = [];
  String? _videoUrl;
  List<String> _tags = [];
  bool _visible = true;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _liked = false;
  String? _createdAt;

  FeedItemDto copyWith({
    int? id,
    int? userId,
    String? userNickname,
    String? userAvatar,
    String? content,
    String? contentType,
    List<String>? imageUrls,
    String? videoUrl,
    List<String>? tags,
    bool? visible,
    int? likeCount,
    int? commentCount,
    bool? liked,
    String? createdAt,
  }) => FeedItemDto(
    id: id ?? _id,
    userId: userId ?? _userId,
    userNickname: userNickname ?? _userNickname,
    userAvatar: userAvatar ?? _userAvatar,
    content: content ?? _content,
    contentType: contentType ?? _contentType,
    imageUrls: imageUrls ?? _imageUrls,
    videoUrl: videoUrl ?? _videoUrl,
    tags: tags ?? _tags,
    visible: visible ?? _visible,
    likeCount: likeCount ?? _likeCount,
    commentCount: commentCount ?? _commentCount,
    liked: liked ?? _liked,
    createdAt: createdAt ?? _createdAt,
  );

  int? get id => _id;

  int? get userId => _userId;

  String? get userNickname => _userNickname;

  String? get userAvatar => _userAvatar;

  String? get content => _content;

  String? get contentType => _contentType;

  List<String> get imageUrls => _imageUrls;

  String? get videoUrl => _videoUrl;

  List<String> get tags => _tags;

  bool get visible => _visible;

  int get likeCount => _likeCount;

  int get commentCount => _commentCount;

  bool get liked => _liked;

  String? get createdAt => _createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['userId'] = _userId;
    map['userNickname'] = _userNickname;
    map['userAvatar'] = _userAvatar;
    map['content'] = _content;
    map['contentType'] = _contentType;
    map['imageUrls'] = _imageUrls;
    map['videoUrl'] = _videoUrl;
    map['tags'] = _tags;
    map['visible'] = _visible;
    map['likeCount'] = _likeCount;
    map['commentCount'] = _commentCount;
    map['liked'] = _liked;
    map['createdAt'] = _createdAt;
    return map;
  }

  @override
  String toString() {
    return 'Post{id: $_id, userId: $_userId, userNickname: $_userNickname, userAvatar: $_userAvatar, content: $_content, contentType: $_contentType, imageUrls: $_imageUrls, videoUrl: $_videoUrl, tags: $_tags, visible: $_visible, likeCount: $_likeCount, commentCount: $_commentCount, createdAt: $_createdAt}';
  }
}