import 'dart:async';
import 'package:azure_ad_oauth/model/config.dart';
import 'package:azure_ad_oauth/model/token.dart';
import 'package:azure_ad_oauth/request/authorization_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

    var authResult = await Navigator.of(_config.context!)
        .push(MaterialPageRoute(builder: (context) {
      return RequestCodeInterface(url: initialURL);
    }));

    if (authResult is Exception) {
      return Future.error(authResult);
    }

    return authResult;
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
  InAppWebViewController? wvController;

  String _error = '';

  Future<void> clearCache() async {
    await wvController?.clearCache();
    wvController = null;
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
          body: _error.isNotEmpty
              ? _ErrorMsg(err: _error)
              : InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      clearCache: true,
                      userAgent: widget.userAgent ?? '',
                      javaScriptEnabled: true,
                      incognito: true,
                      cacheEnabled: false,
                    ),
                  ),
                  onWebViewCreated: (InAppWebViewController controller) {
                    wvController = controller;
                  },
                  onLoadStart: (InAppWebViewController controller, Uri? url) {
                    //log('onLoadStart: ${url.toString()}');
                  },
                  onLoadStop:
                      (InAppWebViewController controller, Uri? uri) async {
                    //log('onLoadStop: ${uri.toString()}');
                    if (uri!.queryParameters['error'] != null) {
                      await clearCache();
                      setState(() {
                        if (uri.queryParameters['error'] == 'access_denied') {
                          if (uri.queryParameters['error_subcode'] ==
                              'cancel') {
                            _error = 'Authentication cancelled';
                          } else {
                            _error = 'Access denied';
                          }
                        } else {
                          _error = uri.queryParameters['error']!;
                        }
                      });
                    }

                    if (uri.queryParameters['code'] != null) {
                      await clearCache();
                      Navigator.of(context).pop(uri.queryParameters['code']);
                    }
                  },
                  onProgressChanged:
                      (InAppWebViewController controller, int progress) {
                    //log('onProgressChanged: ${progress.toString()}');
                  },
                  onConsoleMessage: (InAppWebViewController controller,
                      ConsoleMessage consoleMessage) {
                    //log('onConsoleMessage: ${consoleMessage.message}');
                  },
                  onLoadError:
                      (InAppWebViewController wvc, Uri? u, int c, String s) {
                    //log('onLoadError: [$c]: $s');
                    if (c == -10) return;
                    setState(() {
                      if (c == -2) {
                        _error =
                            'Network Error: Could not contact Authentication '
                            'Provider. Please check your Internet connection.';
                      } else {
                        _error = s;
                      }
                    });
                  },
                  onLoadHttpError:
                      (InAppWebViewController wvc, Uri? u, int c, String s) {
                    //log('onLoadHttpError: [$c]: $s');
                    setState(() {
                      _error = s;
                    });
                  },
                ),
        ));
  }
}

class _ErrorMsg extends StatelessWidget {
  const _ErrorMsg({Key? key, required this.err}) : super(key: key);
  final String err;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                err,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(Exception(err));
              },
              child: const Text('< Go back'),
            ),
          ]),
    );
  }
}
