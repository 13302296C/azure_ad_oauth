import 'dart:async';
import 'dart:developer';
import 'package:azure_ad_oauth/model/config.dart';
import 'package:azure_ad_oauth/model/token.dart';
import 'package:azure_ad_oauth/request/authorization_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class RequestCode {
  final Config _config;
  late AuthorizationRequest _authorizationRequest;

  static Exception get ex =>
      Exception('Access denied or authentation canceled.');

  RequestCode(Config config) : _config = config {
    _authorizationRequest = AuthorizationRequest(config);
  }

  Future<String?> requestCode() async {
    if (_config.context == null) return null;
    final String urlParams = _constructUrlParams();
    String initialURL =
        ('${_authorizationRequest.url}?$urlParams').replaceAll(' ', '%20');

    return await Navigator.of(_config.context!)
        .push<String?>(MaterialPageRoute<String?>(builder: (context) {
      return RequestCodeInterface(url: initialURL);
    }));
  }

  Future<void> clearCookies() async {
    // no need to clear it here, as we clear it on exit during token request
  }

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params
        .forEach((String key, String value) => queryParams.add('$key=$value'));
    return queryParams.join('&');
  }

  Future<Token> requestToken() {
    throw Exception('Unimplemented Error');
  }
}

class RequestCodeInterface extends StatefulWidget {
  const RequestCodeInterface({Key? key, required this.url, this.userAgent})
      : super(key: key);
  final String url;
  final String? userAgent;
  @override
  State<RequestCodeInterface> createState() => _RequestCodeInterfaceState();
}

class _RequestCodeInterfaceState extends State<RequestCodeInterface> {
  final flutterWebviewPlugin = FlutterWebviewPlugin();

  String error = '';
  @override
  void initState() {
    flutterWebviewPlugin.onUrlChanged.listen((String url) async {
      var uri = Uri.parse(url);
      if (uri.queryParameters['error'] != null) {
        await clearCache();
        flutterWebviewPlugin.close();
        Navigator.of(context).pop(RequestCode.ex);

        //_onCodeListener.add(null);
      }

      if (uri.queryParameters['code'] != null) {
        await clearCache();
        flutterWebviewPlugin.close();
        Navigator.of(context).pop(uri.queryParameters['code']);
      }
    });
    flutterWebviewPlugin.onProgressChanged.listen((event) {});
    flutterWebviewPlugin.onHttpError.listen((event) {
      log(event.toString());

      flutterWebviewPlugin.close();
      setState(() {
        error = event.toString();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> clearCache() async {
    await flutterWebviewPlugin.cleanCookies();
    await flutterWebviewPlugin.clearCache();
  }

  ///
  Future<void> launchAuth() async {
    await flutterWebviewPlugin.launch(
      widget.url,
      withJavascript: true,
      clearCache: true,
      clearCookies: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await clearCache();
        // ignore: use_build_context_synchronously
        Navigator.pop(context, null);
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Authenticate"),
          ),
          body: Center()),
    );
  }
}
