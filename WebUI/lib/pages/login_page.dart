import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;
import 'package:webui/controllers/CaptchaController.dart';
import 'package:webui/controllers/UserController.dart';

import '../widget/AsyncButton.dart';

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
          Expanded(child: Container(color: Theme
              .of(context)
              .colorScheme
              .onSecondaryFixed)),
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
    if (await UserController.adminCheck()) {
      if (!mounted) return;
      context.go('/main');
      return;
    }
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _loadCaptcha() async {
    final body = await CaptchaController.captcha();
    if (body == null) {
      if (mounted) setState(() => _errorMessage = '验证码加载失败');
      return;
    }
    if (!mounted) return;
    setState(() {
      _captchaToken = body.token;
      _captchaSvg = body.svg;
    });
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

    await _login();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _login() async {
    final user = await UserController.login(
        _usernameController.text, _passwordController.text, _captchaToken,
        _captchaController.text);
    if (!mounted) return;

    if (user.$1 == 200) {
      if (await UserController.adminCheck()) {
        if (!mounted) return;
        context.go('/main');
      } else {
        setState(() => _errorMessage = '非管理员账户，无权限登录');
      }
    } else {
      setState(() => _errorMessage = user.$2);
    }
    _refreshCaptcha();
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
      return const SizedBox(
          width: 400, child: Center(child: CircularProgressIndicator()));
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
                  Text('管理系统后台', style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium, textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(border: OutlineInputBorder(),
                    labelText: '用户名 (支持邮箱)',
                    prefixIcon: Icon(Icons.person)),
                validator: (value) {
                  if (value?.isEmpty ?? true) return '请输入用户名';
                  if (value!.length < 8) return '用户名至少 8 个字符';
                  if (value.length > 16) return '用户名超过 16 个字符';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: Padding(
                    padding: EdgeInsetsGeometry.only(right: 4),
                    child: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons
                          .visibility),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return '请输入密码';
                  if (value!.length < 8) return '密码至少 8 个字符';
                  if (value.length > 16) return '密码超过 16 个字符';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _captchaController,
                      decoration: InputDecoration(border: OutlineInputBorder(),
                          labelText: '验证码',
                          prefixIcon: const Icon(Icons.security)),
                      maxLength: 4,
                      buildCounter: (_,
                          {required currentLength, required isFocused, maxLength}) => null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_captchaSvg.isNotEmpty)
                    GestureDetector(
                      onTap: _refreshCaptcha,
                      child: Center(child: SvgPicture.string(
                          _captchaSvg, width: 130, height: 48)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AsyncButton(child: Text('登 录')).action(() async {
                if (_isLoading) {
                  return false;
                }
                _submit();
                return true;
              }),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme
                        .of(context)
                        .colorScheme
                        .error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
