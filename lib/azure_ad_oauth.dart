library azure_ad_oauth;

import 'dart:async';
import 'storage/auth_storage.dart';
import 'model/config.dart';
import 'model/token.dart';
import 'request_token.dart';
import 'request_code/request_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

export 'model/config.dart';

class AzureADoAuth {
  final Config _config;
  final AuthStorage _authStorage;
  Token? _token;
  late RequestCode _requestCode;
  late RequestToken _requestToken;
  String tokenIdentifier;

  bool get isLoggedIn => Token.tokenIsValid(_token);

  AzureADoAuth(config, {this.tokenIdentifier = 'Token'})
      : _config = config,
        _authStorage = AuthStorage(identifier: tokenIdentifier) {
    _requestCode = RequestCode(_config);
    _requestToken = RequestToken(_config);
  }

  Future<void> login({bool removeOldTokenOnFirstLogin = false}) async {
    if (removeOldTokenOnFirstLogin) await _removeOldTokenOnFirstLogin();
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
  }

  Future<String?> getAccessToken() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();

    return _token?.accessToken;
  }

  Future<String?> getIdToken() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.idToken;
  }

  Future<String?> getRefreshToken() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.refreshToken;
  }

  Future<String?> getTokenType() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.tokenType;
  }

  Future<DateTime?> getIssueTimeStamp() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.issueTimeStamp;
  }

  Future<DateTime?> getExpireTimeStamp() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.expireTimeStamp;
  }

  Future<int?> getExpiresIn() async {
    if (!Token.tokenIsValid(_token)) await _performAuthorization();
    return _token?.expiresIn;
  }

  Future<void> logout() async {
    await _authStorage.clear();
    if (!kIsWeb) {
      await _requestCode.clearCookies();
    }
    _token = null;
  }

  ///
  Future<void> _performAuthorization() async {
    // load token from cache
    _token ??= await _authStorage.loadTokenFromStorageToCache()
      ?..tokenRefreshAdvanceInSeconds = _config.tokenRefreshAdvanceInSeconds;

    // refresh flow doesn't work on web - iOS only
    if (!kIsWeb) await _performRefreshAuthFlow();

    if (!Token.tokenIsValid(_token)) await _performFullAuthFlow();

    //save token to cache
    await _authStorage.saveTokenToStorage(_token);
  }

  Future<void> _performFullAuthFlow() async {
    String? code;
    try {
      if (kIsWeb) {
        _token = await _requestCode.requestToken();
      } else {
        code = await _requestCode.requestCode();
        if (code == null) {
          throw Exception('Access denied or authentication cancelled.');
        }
        _token = await _requestToken.requestToken(code);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _performRefreshAuthFlow() async {
    if (_token?.refreshToken != null) {
      try {
        _token = await _requestToken.requestRefreshToken(_token!.refreshToken);
      } catch (e) {
        //do nothing (because later we try to do a full oauth code flow request)
      }
    }
  }

  /// If you want to remove the old token on first login, you can use this method by
  /// setting the parameter [removeOldTokenOnFirstLogin] to true in the login method.
  Future<void> _removeOldTokenOnFirstLogin() async {
    var prefs = await SharedPreferences.getInstance();
    var keyFreshInstall = 'freshInstall';
    if (!prefs.getKeys().contains(keyFreshInstall)) {
      await logout();
      await prefs.setBool(keyFreshInstall, false);
    }
  }
}
