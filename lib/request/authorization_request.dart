import 'package:azure_ad_oauth/model/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthorizationRequest {
  String? url;
  String? redirectUrl;
  late Map<String, String> parameters;
  Map<String, String>? headers;
  bool? fullScreen;
  bool? clearCookies;

  AuthorizationRequest(Config config,
      {bool this.fullScreen = true, bool this.clearCookies = false}) {
    url = config.authorizationUrl;
    redirectUrl = config.redirectUri;
    parameters = {
      'client_id': config.clientId,
      'response_type': config.responseType,
      'redirect_uri': config.redirectUri,
      'scope': config.scope
    };
    if (kIsWeb) {
      parameters.addAll({'nonce': config.nonce});
    }
  }
}
