import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import 'auth_controller.dart';

class LoginPage extends BasePage {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BasePageState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'demo');
  final _passwordCtrl = TextEditingController(text: 'demo123');
  bool _obscure = true;

  @override
  void onPageShow() {
    AppLog.d('[LoginPage] onPageShow');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authControllerProvider);

        // 监听登录失败，弹 SnackBar
        ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (prev, next) {
          if (next.hasError && !next.isLoading) {
            final err = next.error;
            final msg = err is ApiException ? err.message : '登录失败';
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg)));
          }
        });

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
                        onFieldSubmitted: (_) => _submit(ref),
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
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? '密码至少 6 位' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : () => _submit(ref),
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
      },
    );
  }
}
