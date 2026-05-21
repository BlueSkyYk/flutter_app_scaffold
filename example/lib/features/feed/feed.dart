/// feed feature 的公共 API barrel。
///
/// 跨域消费者(router、其他 feature)只通过这个文件 import,
/// 内部 data/domain/presentation 的具体路径作为实现细节封装。
library;

export 'domain/feed_item.dart';
export 'presentation/feed_controller.dart' show feedControllerProvider;
export 'presentation/feed_page.dart' show FeedPage;