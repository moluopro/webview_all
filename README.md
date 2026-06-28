# WebView All

[English](https://github.com/moluopro/webview_all/blob/main/webview_all/README.md) | [中文文档](https://github.com/moluopro/webview_all/blob/main/webview_all/README-ZH.md)

A WebView component that supports all Flutter platforms and follows the
[`webview_flutter` platform interface](https://pub.dev/packages/webview_flutter_platform_interface).

|     Platform     | **Support** | **Implementation** |
|-------------|--------------|--------------|
|Android|SDK 24+|[WebView](https://developer.android.com/reference/android/webkit/WebView)|
|iOS|13.0+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Windows|Win10 1809+|[WebView2](https://developer.microsoft.com/microsoft-edge/webview2)|
|macOS|10.15+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Linux|webkit2gtk-4.1|[WebKitGTK](https://webkitgtk.org)|
|OHOS|API 12+|[ArkWeb](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V5/ts-basic-components-web-V5)|
|Web|Any|[js-interop](https://dart.dev/interop/js-interop)|
