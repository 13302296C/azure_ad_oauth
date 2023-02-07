import 'dart:async';
import 'dart:developer';
import 'package:azure_ad_oauth/model/config.dart';
import 'package:azure_ad_oauth/model/token.dart';
import 'package:azure_ad_oauth/request/authorization_request.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final WebViewController _controller = WebViewController();
  String error = '';
  @override
  void initState() {
    if (widget.userAgent != null) _controller.setUserAgent(widget.userAgent);
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setBackgroundColor(Colors.black);
    _controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) async {
        var uri = Uri.parse(request.url);
        if (uri.queryParameters['error'] != null) {
          Navigator.of(context).pop(RequestCode.ex);
        }

        if (uri.queryParameters['code'] != null) {
          try {
            await _controller.clearCache();
            await _controller.clearLocalStorage();
          } catch (e, s) {
            log('Error clearing cache', error: e, stackTrace: s);
          }

          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(uri.queryParameters['code']);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageStarted: (url) {
        //log('Page started loading: $url');
      },
      onPageFinished: (url) {
        //log('Page finished loading: $url');
      },
      onProgress: (progress) {
        //log('Page loading progress: $progress');
      },
      onWebResourceError: (error) {
        //log('Page loading error: $error');
        setState(() {
          this.error = 'Error ${error.errorCode}:\n\n${error.description}';
        });
      },
    ));

    _controller.loadRequest(Uri.parse(widget.url));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> clearCache() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Authenticate'),
        ),
        body: error.isEmpty
            ? WebViewWidget(controller: _controller)
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ignore: prefer_const_constructors
                    Icon(
                      Icons.bug_report,
                      size: 40.0,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 18.0),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )));
  }
}
