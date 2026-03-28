# webview_all_windows

`webview_all_windows` 是 `webview_all` 在 Windows 平台上的实现。底层实现基于 [Microsoft Edge WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2)。

我们尽可能遵循 `webview_flutter` 相同的平台接口和编程模型，基于 `WebViewController`、`WebViewWidget`、`NavigationDelegate` 以及对应平台 API 编写代码，在 Windows 上可以按照相同的方式接入。


## 使用方式

在应用中添加 `webview_all` 依赖，Flutter 会在 Windows 平台自动解析到 `webview_all_windows`。

```yaml
dependencies:
  webview_all:
    path: ../webview_all
```

示例：

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


## 目标平台

- [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
- Windows 10 1809 及以上

在初始化 WebView 之前，请确保目标机器已经安装 WebView2 Runtime。


## 开发环境

- Visual Studio 2019 或更高版本
- Windows 11 SDK `10.0.22000.194` 或更高版本
- 建议将 `nuget.exe` 加入 `PATH`


## 重要说明

- 部分行为可能仍会因为 WebView2 本身的限制，与其他平台存在差异。
- 某些暂时无法正确支持的能力，可能会被实现为带说明的 no-op，或直接抛出 `UnsupportedError`，具体取决于该接口的语义要求。
- 使用了 [`flutter-webview-windows`](https://pub.dev/packages/webview_windows) 的部分代码。
