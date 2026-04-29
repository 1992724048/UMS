import 'dart:convert';
import '../Struct/CaptchaResult.dart';
import '../utils/http.dart';

class CaptchaController {
  static Future<CaptchaResult?> captcha() async {
    try {
      final req = await HttpClient.get('/api/Captcha/get');
      if (req.status != 200) return null;
      return CaptchaResult.fromJson(jsonDecode(req.responseText));
    } catch (_) {
      return null;
    }
  }
}
