import 'package:uuid/uuid.dart';

class TokenGenerator {
  TokenGenerator._();

  static const _uuid = Uuid();

  /// 128-bit UUID v4 token — URL-safe, en az 32 karakter (Gereksinim 18.1)
  static String generate() {
    return _uuid.v4().replaceAll('-', '');
  }
}
