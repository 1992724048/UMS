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

  static Future<(int, String)> login(String username, String password,
      String captcha, String captchaToke) async {
    try {
      final req = await HttpClient.post('/api/User/login', body: jsonEncode({
        'username': username,
        'password': password,
        'captchaToken': captcha,
        'captchaCode': captchaToke
      }));
      if (req.status == 200) {
        final body = jsonDecode(req.responseText);
        return (body['code'] as int, body['message'] as String);
      }
    } catch (_) {}
    return (-1, '请求失败');
  }

  static Future<bool> logout() async {
    try {
      final req = await HttpClient.post('/api/User/logout');
      if (req.status == 200) return true;
    } catch (_) {}
    return false;
  }

  static Future<UserPageResult?> listUsers(int page, int pageSize) async {
    try {
      final req = await HttpClient.get(
          '/api/User/list_users?page=$page&pageSize=$pageSize');

      if (req.status != 200) {
        return null;
      }

      final responseText = req.responseText;
      if (responseText.isEmpty) {
        return null;
      }

      final json = jsonDecode(responseText);
      return UserPageResult.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> delete(int uid) async {
    try {
      final req = await HttpClient.get('api/User/delete_user?id=$uid');
      if (req.status == 200) return true;
    } catch (_) {}
    return false;
  }

  static Future<(int, String)> update(User user) async {
    try {
      final req = await HttpClient.post(
          'api/User/update_user', body: user.toJson());
      if (req.status == 200) {
        final body = jsonDecode(req.responseText);
        return (body['code'] as int, body['message'] as String);
      }
    } catch (_) {}
    return (-1, '请求失败');
  }
}
