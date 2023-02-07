import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  // web page that sets a cookie
  String cookieSetHtml = '''
  <html>
    <head>
      <title>Cookie Test</title>
    </head>
    <body>
      <script>
        document.cookie = "test=1";
      </script>
    </body>''';

  // web page that checks if cookie is set
  String cookieTestHtml = '''
  <html>
    <head>
      <title>Cookie Test</title>
    </head>
    <body>
      <script>
        document.cookie = "test=1";
        if (document.cookie.indexOf("test=1") != -1) {
          document.write("Cookie set");
        } else {
          document.write("Cookie not set");
        }
      </script>
    </body>''';

  testWidgets('checks if WebViewController clears cache', (tester) async {
    final WebViewController controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    Widget buildWebView() {
      return MaterialApp(builder: (context, _) {
        return Scaffold(body: WebViewWidget(controller: controller));
      });
    }

    await tester.pumpWidget(buildWebView());

    // load a page that sets a cookie
    await controller.loadHtmlString(cookieSetHtml);
    await controller.loadHtmlString(cookieTestHtml);
    find.text('Cookie set');
    await controller.clearCache();
    await controller.clearLocalStorage();
    find.text('Cookie not set');
  });
}
