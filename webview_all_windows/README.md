# webview_all_windows

`webview_all_windows` is the Windows platform implementation package for `webview_all`. Its underlying implementation is based on [Microsoft Edge WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2).

This package aims to follow the same platform interface and programming model as `webview_flutter`, so code written around `WebViewController`, `WebViewWidget`, `NavigationDelegate`, and the corresponding platform APIs can also be integrated on Windows in the same overall way.


## Dependency

Add `webview_all` to your application, and Flutter will resolve `webview_all_windows` as the Windows platform implementation package.

```yaml
dependencies:
  webview_all:
    path: ../webview_all
```

Example:

```dart
import 'package:webview_all/webview_all.dart';

final WebViewController controller = WebViewController()
  ..setNavigationDelegate(
    NavigationDelegate(
      onPageFinished: (String url) {},
    ),
  )
  ..loadRequest(Uri.parse('https://flutter.dev'));
```

```dart
WebViewWidget(controller: controller)
```


## Target Platform Requirements

- [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
- Windows 10 1809 and later

Before initializing WebView, make sure that WebView2 Runtime is already installed on the target machine.


## Development Environment Requirements

- Visual Studio 2019 or later
- Windows 11 SDK `10.0.22000.194` or later
- It is recommended to add `nuget.exe` to `PATH`


## Important Notes

- Some capabilities still depend on the limitations of WebView2 itself on Windows, so their behavior may differ from Android, iOS, or macOS.
- For capabilities that cannot currently be supported correctly, they may be implemented as a no-op or throw `UnsupportedError`, depending on the semantics required by the API.
- This project is based on earlier work from [`flutter-webview-windows`](https://pub.dev/packages/webview_windows).
