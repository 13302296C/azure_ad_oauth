import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:math';
import 'package:azure_ad_oauth/model/config.dart';
import 'package:azure_ad_oauth/model/token.dart';
import 'package:azure_ad_oauth/request/authorization_request.dart';
import 'package:flutter/material.dart';

class RequestCode {
  static Exception ex = Exception('Access denied or authentation canceled.');
  final StreamController<Map<String, String>> _onCodeListener =
      StreamController();

  bool _signonInProcess = false;
  late AuthorizationRequest _authorizationRequest;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  StreamSubscription<bool?>? _popupStatusSubscription;
  html.WindowBase? _popupWin;
  Stream<Map<String, String>>? _onCodeStream;

  RequestCode(Config config) {
    _authorizationRequest = AuthorizationRequest(config);
  }

  Future<Token> requestToken() async {
    late Token token;
    final String urlParams = _constructUrlParams();

    String initialURL =
        ('${_authorizationRequest.url}?$urlParams').replaceAll(' ', '%20');

    _webAuth(initialURL);

    var jsonToken = await _onCode.first;
    token = Token.fromJson(jsonToken);
    await _messageSubscription?.cancel();
    await _popupStatusSubscription?.cancel();
    return token;
  }

  void _webAuth(String initialURL) {
    _messageSubscription = html.window.onMessage.listen((event) {
      var tokenParm = 'access_token';
      if (event.data.toString().contains(tokenParm)) {
        _messageSubscription?.cancel();
        _geturlData(event.data.toString());
      }
      if (event.data.toString().contains('error')) {
        _messageSubscription?.cancel();
        _closeWebWindow();
        throw RequestCode.ex;
      }
    });

    _displayOAuthPrompt(initialURL);

    // Stream to watch when popup closes.
    // If stream subscription fails -
    // the browser is blocking popups...
    _popupStatusSubscription = _popupStatusStream(_popupWin).listen((isClosed) {
      if (isClosed! && _signonInProcess) {
        _onCodeListener.addError(RequestCode.ex);
        _popupStatusSubscription?.cancel();
      }
    })
      ..onError((e, s) {
        _onCodeListener.addError(
            Exception('Popups are blocked. Please allow popups in address bar, '
                'then refresh this page.'));
      });
  }

  /// Display MS Auth popup centered on the screen
  void _displayOAuthPrompt(String initialUrl) {
    int w = 600;
    int h = 600;
    int x = (html.window.outerWidth - w).abs() ~/ 2;
    int y = (html.window.outerHeight - h).abs() ~/ 2;
    String q = 'width=$w,height=$h,top=$y,left=$x';
    // ignore: unsafe_html
    _popupWin = html.window.open(initialUrl, 'WSPM Login', q);
    _signonInProcess = true;
  }

  Stream<bool?> _popupStatusStream(html.WindowBase? popup) async* {
    bool? status, isClosed;
    while (true) {
      status = popup?.closed;
      if (isClosed != status) {
        isClosed = status;
        yield isClosed;
        if (isClosed!) break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _geturlData(String url) {
    Uri uri = Uri.parse(url.replaceFirst('#', '?'));

    if (uri.queryParameters['error'] != null) {
      _onCodeListener.addError(RequestCode.ex);
    } else {
      var token = uri.queryParameters;
      _onCodeListener.add(token);
    }
    _closeWebWindow();
  }

  void _closeWebWindow() {
    _signonInProcess = false;
    if (_popupWin != null) {
      _popupWin?.close();
      _popupWin = null;
    }
  }

  Future<void> clearCookies() async {
    //CookieManager().clearCookies();
  }

  Stream<Map<String, String>> get _onCode =>
      _onCodeStream ??= _onCodeListener.stream.asBroadcastStream();

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params
        .forEach((String key, String value) => queryParams.add('$key=$value'));
    return queryParams.join('&');
  }

  Future<String?> requestCode() {
    throw Exception('Unimplemented Error');
  }
}

class RequestCodeInterface extends StatelessWidget {
  final String url;
  late final String viewId;

  RequestCodeInterface({Key? key, required this.url}) : super(key: key) {
    viewId = getRandString(10).substring(0, 14);
    final iframe = html.IFrameElement()
      ..width = '100%'
      ..height = '100%'
      // ignore: unsafe_html
      ..src = url
      ..style.border = 'none'
      ..style.overflow = 'hidden'
      ..id = viewId
      ..onError.listen((event) {
        //print('error');
      })
      ..onLoad.listen((event) async {
        //
      });
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) => iframe);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }

  String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }
}
