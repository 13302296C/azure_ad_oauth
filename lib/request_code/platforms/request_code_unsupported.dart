import 'package:azure_ad_oauth/model/config.dart';
import 'package:azure_ad_oauth/model/token.dart';

class RequestCode {
  static Exception get ex =>
      Exception('Access denied or authentation canceled.');
  // ignore: unused_field
  final Config _config;
  RequestCode(this._config);

  Future<String?> requestCode() => throw ex;
  Future<Token> requestToken() => throw ex;
  Future<void> clearCookies() => throw ex;
}
