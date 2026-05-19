import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import '../domain/auth_user.dart';
import 'auth_controller.dart';

/// 登录页。
///
/// 同时需要 Riverpod `ref` 和页面生命周期(打日志),用 [ConsumerStatefulWidget]
/// + [PageLifecycleMixin] 组合 —— 单一 State 类、ref 直接可用、不需要在 build
/// 里再嵌一层 Consumer。
///
/// 对比:
/// - 只要 ref、不要生命周期 → ConsumerWidget(见 HomePage)
/// - 只要生命周期、不要 ref → BasePage + BasePageState
/// - 两者都要 → 当前这个写法
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with PageLifecycleMixin<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'demo');
  final _passwordCtrl = TextEditingController(text: 'demo123');
  bool _obscure = true;

  @override
  void onPageShow() => AppLog.d('[LoginPage] onPageShow');

  @override
  void onPageHide() => AppLog.d('[LoginPage] onPageHide');

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// 触发登录。事件回调里用 `ref.read(provider.notifier)` 调动作:
  /// - `.notifier` → AuthController 实例
  /// - `read` 而非 `watch` → 这里只是触发动作,不订阅状态
  /// 错误由 [AsyncValue.guard] 装入 state.error,UI 通过下面的 ref.listen 处理。
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    // ConsumerState 自带 ref 字段,无需再套 Consumer。
    // 三件套:watch 订阅(触发重建)、read 取值/调动作(不重建)、listen 副作用(不重建)。
    final auth = ref.watch(authControllerProvider);

    // listen:登录失败时弹 SnackBar。副作用必须用 listen,不要写在 build 主体里。
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final err = next.error;
        final msg = err is ApiException ? err.message : '登录失败';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });
    // 登录成功跳 /home 由 routerProvider 的 redirect 自动处理。

    final isLoading = auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.flutter_dash,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '欢迎回来',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用 demo / demo123 登录',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameCtrl,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '账号',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入账号' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    enabled: !isLoading,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? '密码至少 6 位' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : () {},
                    child: const Text('忘记密码？'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
