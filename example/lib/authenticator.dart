import 'package:azure_ad_oauth/azure_ad_oauth.dart';
import 'package:azure_ad_oauth/jwt.dart';
import 'package:flutter/foundation.dart';

class OAuth extends ChangeNotifier {
  /// Tenant ID of you Azure account
  static const String tenantId = ''; // TODO: set your tenant ID

  /// Client ID of you Azure application
  static const String clientId = ''; // TODO: set your client ID

  late final AzureADoAuth oAuth;
  late final Config config;
  Map<String, dynamic> map = {};
  bool loginInProgress = false;

  //singleton pattern
  static final OAuth _instance = OAuth._();

  OAuth._() {
    if (tenantId.isEmpty || clientId.isEmpty) {
      throw Exception('Please set tenantId and clientId');
    }
    String redirectUri;
    if (kIsWeb) {
      final currentUri = Uri.base;
      redirectUri = Uri(
        host: currentUri.host,
        scheme: currentUri.scheme,
        port: currentUri.port,
        path: '/authRedirect.html',
      ).toString();
    } else {
      redirectUri = 'msal$clientId://auth';
    }
    config = Config(
      tenantId: tenantId,
      clientId: clientId,
      scope: 'openid profile offline_access',
      responseType: kIsWeb ? 'id_token+token' : 'code',
      redirectUri: redirectUri,
      // the following sets the token refresh to 2 minutes
      //before the token expires.
      // This protects you from the token expiring during the API call.
      tokenRefreshAdvanceInSeconds: 120,
    );
    oAuth = AzureADoAuth(config);
  }

  static OAuth get instance => _instance;
  bool get isLoggedIn => oAuth.isLoggedIn;

  /// use this for all your API calls
  Future<String?> get token => oAuth.getIdToken();

  /// Get JWT data
  Future<Map<String, dynamic>> getJwtData() async {
    if (!oAuth.isLoggedIn) return {};
    return Jwt.parseJwt((await oAuth.getIdToken())!);
  }

  /// Login to Azure AD
  Future<void> login() async {
    loginInProgress = true;
    notifyListeners();
    await oAuth.login();
    map = await getJwtData();
    loginInProgress = false;
    notifyListeners();
  }

  /// Logout from Azure AD
  Future<void> logout() async {
    loginInProgress = true;
    notifyListeners();
    await oAuth.logout();
    map = {};
    loginInProgress = false;
    notifyListeners();
  }
}
