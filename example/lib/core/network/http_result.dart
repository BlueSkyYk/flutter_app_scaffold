/// code : 200
/// message : "ok"
/// data : null
class HttpResult<T> {
  HttpResult({int? code, String? message, T? data}) {
    _code = code;
    _message = message;
    _data = data;
  }

  HttpResult.fromJson(Map<String, dynamic> json) {
    _code = json['code'];
    _message = json['message'];
    _data = json['data'];
  }

  int? _code;
  String? _message;
  T? _data;

  HttpResult copyWith({int? code, String? message, T? data}) => HttpResult(
    code: code ?? _code,
    message: message ?? _message,
    data: data ?? _data,
  );

  int? get code => _code;

  String? get message => _message;

  T? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    map['code'] = _code;
    map['data'] = _data;
    return map;
  }
}

class PageModel<T> {
  PageModel({
    int? total,
    int? page,
    int? pageSize,
    bool? isFirstPage,
    bool? isLastPage,
    List<T>? list,
  }) {
    _total = total ?? 0;
    _page = page ?? 1;
    _pageSize = pageSize ?? 10;
    _isFirstPage = isFirstPage ?? true;
    _isLastPage = isLastPage ?? true;
    _list = list ?? [];
  }

  PageModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) itemParser,
  ) {
    _total = json['total'] ?? 0;
    _page = json['page'] ?? 1;
    _pageSize = json['pageSize'] ?? 10;
    _isFirstPage = json['isFirstPage'] ?? json['firstPage'] ?? true;
    _isLastPage = json['isLastPage'] ?? json['lastPage'] ?? true;

    // 解析列表数据
    if (json['list'] != null && json['list'] is List) {
      _list = (json['list'] as List).map((item) => itemParser(item)).toList();
    } else {
      _list = [];
    }
  }

  int _total = 0;
  int _page = 1;
  int _pageSize = 10;
  bool _isFirstPage = true;
  bool _isLastPage = true;
  List<T> _list = [];

  PageModel<T> copyWith({
    int? total,
    int? page,
    int? pageSize,
    bool? isFirstPage,
    bool? isLastPage,
    List<T>? list,
  }) => PageModel<T>(
    total: total ?? _total,
    page: page ?? _page,
    pageSize: pageSize ?? _pageSize,
    isFirstPage: isFirstPage ?? _isFirstPage,
    isLastPage: isLastPage ?? _isLastPage,
    list: list ?? _list,
  );

  PageModel<D> cover<D, R>({
    int? total,
    int? page,
    int? pageSize,
    bool? isFirstPage,
    bool? isLastPage,
    required List<R>? list,
    required D Function(R item) itemCover,
  }) => PageModel<D>(
    total: total ?? _total,
    page: page ?? _page,
    pageSize: pageSize ?? _pageSize,
    isFirstPage: isFirstPage ?? _isFirstPage,
    isLastPage: isLastPage ?? _isLastPage,
    list: list?.map(itemCover).toList(),
  );

  /// 总条数
  int get total => _total;

  /// 当前页（从 1 开始）
  int get page => _page;

  /// 每页数量
  int get pageSize => _pageSize;

  /// 是否首页
  bool get isFirstPage => _isFirstPage;

  /// 是否末页
  bool get isLastPage => _isLastPage;

  /// 数据列表
  List<T> get list => _list;

  /// 是否为空
  bool get isEmpty => _list.isEmpty;

  /// 是否不为空
  bool get isNotEmpty => _list.isNotEmpty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total'] = _total;
    map['page'] = _page;
    map['pageSize'] = _pageSize;
    map['isFirstPage'] = _isFirstPage;
    map['isLastPage'] = _isLastPage;
    map['list'] = _list;
    return map;
  }
}
