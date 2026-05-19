/// auth feature 的公共 API barrel。
///
/// 跨域消费者(router、其他 feature)只通过这个文件 import,
/// 内部 data/domain/presentation 的具体路径作为实现细节封装。
/// 想要让某个符号"对外可见",就在这里 export 一行。
library;

export 'domain/auth_user.dart';
export 'presentation/auth_controller.dart' show authControllerProvider;
export 'presentation/login_page.dart' show LoginPage;
