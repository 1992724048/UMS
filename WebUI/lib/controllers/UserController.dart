import 'dart:convert';

import 'package:webui/Struct/User.dart';

import '../utils/http.dart';

class UserController {
  static Future<bool> adminCheck() async {
    try {
      final req = await HttpClient.get('/api/User/admin_check');
      if (req.status == 200) return true;
    } catch (_) {}
    return false;
  }

  static Future<bool> login(
    String username,
    String password,
    String captcha,
    String captchaToke,
  ) async {
    try {
      final req = await HttpClient.post(
        '/api/User/login',
        body: jsonEncode({
          'username': username,
          'password': password,
          'captchaToken': captcha,
          'captchaCode': captchaToke,
        }),
      );

      if (req.status == 200) {
        final body = jsonDecode(req.responseText);
        if (body['code'] == 200) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> logout() async {
    try {
      final req = await HttpClient.post('/api/User/logout');
      if (req.status == 200) return true;
    } catch (_) {}
    return false;
  }
}
