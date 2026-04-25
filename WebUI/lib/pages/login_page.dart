import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import '../utils/http.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static int _imgCounter = 0;
  late final String _imgId;

  @override
  void initState() {
    super.initState();
    _imgCounter++;
    _imgId = 'login-bg-$_imgCounter';
    _mountBgImage();
  }

  void _mountBgImage() {
    final img = web.document.createElement('img') as web.HTMLImageElement;
    img.id = _imgId;
    img.src = 'https://api.elaina.cat/random/';
    img.style
      ..position = 'fixed'
      ..left = '0'
      ..top = '0'
      ..width = 'calc(100vw - 400px)'
      ..height = '100vh'
      ..objectFit = 'cover'
      ..zIndex = '9999'
      ..pointerEvents = 'none';
    web.document.body!.appendChild(img);
  }

  @override
  void dispose() {
    web.document.getElementById(_imgId)?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(child: Container(color: Theme.of(context).colorScheme.onSecondaryFixed)),
          _LoginInput(),
        ],
      ),
    );
  }
}

class _LoginInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isChecking = true;
  String? _errorMessage;
  String _captchaToken = '';
  String _captchaSvg = '';

  @override
  void initState() {
    super.initState();
    _autoCheck();
    _loadCaptcha();
  }

  Future<void> _autoCheck() async {
    try {
      final req = await HttpClient.get('/api/System/admin_check');
      if (!mounted) return;
      if (req.status == 200) {
        context.go('/main');
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _loadCaptcha() async {
    try {
      final req = await HttpClient.get('/api/Captcha/get');
      if (!mounted) return;
      final body = jsonDecode(req.responseText);
      setState(() {
        _captchaToken = body['token'];
        _captchaSvg = body['svg'];
      });
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '验证码加载失败');
    }
  }

  void _refreshCaptcha() => _loadCaptcha();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_captchaToken.isEmpty || _captchaController.text.isEmpty) {
      setState(() => _errorMessage = '请完成验证码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _login();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    try {
      final req = await HttpClient.post(
        '/api/User/login',
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'captchaToken': _captchaToken,
          'captchaCode': _captchaController.text,
        }),
      );

      if (!mounted) return;

      if (req.status == 200) {
        final body = jsonDecode(req.responseText);
        if (body['code'] == 200) {
          final adminReq = await HttpClient.get('/api/System/admin_check');
          if (!mounted) return;
          if (adminReq.status == 200) {
            context.go('/main');
          } else {
            setState(() => _errorMessage = '非管理员账户，无权限登录');
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) context.go('/');
          }
        } else {
          setState(() => _errorMessage = body['message'] ?? '用户名或密码错误');
          _refreshCaptcha();
        }
      } else {
        setState(() => _errorMessage = '请求失败（${req.status}）');
        _refreshCaptcha();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '网络错误：$e');
      _refreshCaptcha();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SizedBox(width: 400, child: Center(child: CircularProgressIndicator()));
    }

    return SizedBox(
      width: 400,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 32),
                  const SizedBox(width: 15),
                  Text('管理系统后台', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return '请输入用户名';
                  if (value!.length < 3) return '用户名至少 3 个字符';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: Padding(
                    padding: EdgeInsetsGeometry.only(right: 4),
                    child: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return '请输入密码';
                  if (value!.length < 3) return '密码至少 3 个字符';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_captchaSvg.isNotEmpty)
                GestureDetector(
                  onTap: _refreshCaptcha,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: SvgPicture.string(
                        _captchaSvg,
                        width: 130,
                        height: 48,
                        placeholderBuilder: (_) =>
                            const SizedBox(width: 130, height: 48, child: Center(child: Text('加载中'))),
                      ),
                    ),
                  ),
                ),
              if (_captchaSvg.isNotEmpty) const SizedBox(height: 8),
              TextFormField(
                controller: _captchaController,
                decoration: InputDecoration(
                  labelText: '验证码',
                  prefixIcon: const Icon(Icons.security),
                  suffixIcon: _captchaSvg.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _refreshCaptcha)
                      : null,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 4,
                validator: (value) {
                  if (value?.isEmpty ?? true) return '请输入验证码';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('登 录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
