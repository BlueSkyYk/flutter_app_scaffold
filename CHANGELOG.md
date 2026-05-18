## 0.1.0

首个版本。包含：

- AppBootstrap / AppInitializer：启动初始化编排
- AppConfig / AppEnv：环境与全局配置
- AppLog：基于 logger 的日志门面
- KvStorage / PrefsStorage / SecureStorage：通用存储
- DioClient + ApiResult + ApiException：网络层与统一异常
- AuthInterceptor / AppLogInterceptor / RetryInterceptor：常用拦截器
- AppRouter（go_router 封装）+ appRouteObserver：路由
- BasePage / BasePageState：页面生命周期（替代 GetX 方案）
- AppTheme / AppColors / AppTextStyles：主题
- LoadingView / EmptyView / ErrorView / AsyncValueView / KeepAliveWrapper：通用 UI
- GlobalErrorHandler / ErrorReporter：全局错误兜底与上报抽象
