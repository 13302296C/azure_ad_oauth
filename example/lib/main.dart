import 'authenticator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Azure AD oAuth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: OAuth.instance..config.context = context,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (OAuth.instance.isLoggedIn &&
                      !OAuth.instance.loginInProgress)
                    Text(
                        'WELCOME\n ${OAuth.instance.map['name']}\n(${OAuth.instance.map['preferred_username']})',
                        textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(200, 50),
                    ),
                    onPressed: OAuth.instance.loginInProgress
                        ? null
                        : () {
                            OAuth.instance.isLoggedIn
                                ? OAuth.instance.logout().onError(
                                    (error, stackTrace) =>
                                        showErrorToast(error.toString()))
                                : OAuth.instance.login().onError(
                                    (error, stackTrace) =>
                                        showErrorToast(error.toString()));
                          },
                    child: OAuth.instance.loginInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : Text(OAuth.instance.isLoggedIn ? 'Logout' : 'Login'),
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// Show error message
  Future<void> showErrorToast(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
