class CaptchaResult {
  final String token;
  final String svg;

  CaptchaResult(this.token, this.svg);

  static CaptchaResult? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final token = json['token'] as String?;
    final svg = json['svg'] as String?;

    if (token == null || svg == null) {
      return null;
    }

    return CaptchaResult(token, svg);
  }
}