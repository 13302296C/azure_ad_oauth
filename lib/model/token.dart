import 'package:azure_ad_oauth/jwt.dart';

class Token {
  /// If token is too clode to expiry -
  /// refresh it. Default is 5 minutes (300 seconds)
  int tokenRefreshAdvanceInSeconds;
  String? accessToken;
  String? idToken;
  String? tokenType;
  String? refreshToken;
  DateTime? issueTimeStamp;
  DateTime? expireTimeStamp;
  int? expiresIn;

  Token({this.tokenRefreshAdvanceInSeconds = 300});

  factory Token.fromJson(Map<String, dynamic>? json) => Token.fromMap(json);

  Map toMap() => Token.toJsonMap(this);

  @override
  String toString() => Token.toJsonMap(this).toString();

  static Map toJsonMap(Token? model) {
    Map ret = {};
    if (model != null) {
      if (model.accessToken != null) {
        ret['access_token'] = model.accessToken;
      }
      if (model.idToken != null) {
        ret['id_token'] = model.idToken;
      }
      if (model.tokenType != null) {
        ret['token_type'] = model.tokenType;
      }
      if (model.refreshToken != null) {
        ret['refresh_token'] = model.refreshToken;
      }
      if (model.expiresIn != null) {
        ret['expires_in'] = model.expiresIn;
      }
      if (model.expireTimeStamp != null) {
        ret['expire_timestamp'] = model.expireTimeStamp!.millisecondsSinceEpoch;
      }
    }
    return ret;
  }

  static Token fromMap(Map? map) {
    if (map == null) throw Exception('No token received');
    //error handling as described in https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow#error-response-1
    if (map['error'] != null) {
      throw Exception('Error during token request: ${map['error']}:'
          ' ${map['error_description']}');
    }

    Token model = Token();
    model.accessToken = map['access_token'];
    model.idToken = map['id_token'];

    Map<String, dynamic> payload = {...Jwt.parseJwt(model.idToken!)};
    final iat = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        .add(Duration(seconds: payload['iat']));
    final exp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        .add(Duration(seconds: payload['exp']))
        .add(Duration(seconds: -model.tokenRefreshAdvanceInSeconds));

    model.tokenType = map['token_type'];
    model.expiresIn = map['expires_in'] is int
        ? map['expires_in']
        : int.tryParse(map['expires_in'].toString()) ?? 60;
    model.refreshToken = map['refresh_token'];
    model.issueTimeStamp = iat.toUtc();
    model.expireTimeStamp = exp.toUtc();
    return model;
  }

  static bool isExpired(Token? token) {
    return token?.expireTimeStamp?.isBefore(DateTime.now().toUtc()) ?? true;
  }

  static bool tokenIsValid(Token? token) {
    if (token == null) return false;
    if (Token.isExpired(token)) return false;
    if (token.accessToken == null) return false;
    return true;
  }
}
