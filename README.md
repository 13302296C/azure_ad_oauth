# Azure AD oAuth client.

Fully automated oAuth client for Azure Active Directory. All you need to call is `login()`, `logout()`, and `await OAuth.instance.token` to get your token. Everything else is taken care of by the plugin behind the scenes.

## How to use this plugin

1. Copy `authenticator.dart` file from the example's lib folder and provide your `tenantId` and `clientId` values, update other settings as necessary. This class is using singleton pattern with `ChangeNotifier`, so you can use it anywhere in your app.

2. Provide `context` to the config berfore calling `login()` method something like so:

```dart
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: OAuth.instance..config.context = context,
        builder: (context, _) {
            ...
```

3. Now you can call `login()` and `logout()` methods. To make authenticated calls - add `Authorizetion: Bearer ${await OAuth.instance.token}` to your request headers.


## Web setup:

> Please note: web auth done in popup only. Due to some browser security restrictions, embedding auth screen in `iframe` tag is not possible.

1. For local testing - register Web App in AAD and whitelist the following URL:
```
http://localhost:45678/authRedirect.html
```

2. For local testing - add following config to your `launch.json`:

```json
        {
            "name": "Web Chrome",
            "request": "launch",
            "type": "dart",
            "args": ["-d", "chrome","--web-port", "45678"],
        },
```

3. Add `authRedirect.html` file to your `web` folder with the following content:

```html
<script>
    window.opener.postMessage(window.location.href, '*');
</script>
```

You are done!
