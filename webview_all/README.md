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


## Quick Start

1. Instantiate a `WebViewController`:

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse('https://flutter.dev'));
```

2. Pass `controller` to `WebViewWidget`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: controller),
  );
}
```

For more details, see the [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
and [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html) documentation.


## Platform Features

Many classes provide subclasses, or expose the underlying platform implementation, so that you can access platform-specific capabilities.

If you want to access platform features, first add the corresponding platform implementation package to your app or package:

* **Android**: [webview_flutter_android](https://pub.dev/packages/webview_flutter_android)
* **iOS/macOS**: [webview_flutter_wkwebview](https://pub.dev/packages/webview_flutter_wkwebview)
* **Windows**: [webview_all_windows](https://pub.dev/packages/webview_all_windows)
* **Linux**: [webview_all_linux](https://pub.dev/packages/webview_all_linux)
* **OHOS**: [webview_all_ohos](https://pub.dev/packages/webview_all_ohos)
* **Web**: [webview_all_web](https://pub.dev/packages/webview_all_web)

Then, import the corresponding platform implementation package in your app or package:

```dart
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_all_windows/webview_all_windows.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_ohos/webview_all_ohos.dart';
```

After that, you can access additional capabilities through the platform implementation.  
[WebViewController], [WebViewWidget], [NavigationDelegate], and [WebViewCookieManager]
all delegate their functionality to the implementation provided by the current platform. Below are two common ways to access them, with examples following.

1. Pass the creation params class provided by the platform implementation to the `fromPlatformCreationParams`
   constructor, such as `WebViewController.fromPlatformCreationParams`,
   `WebViewWidget.fromPlatformCreationParams`, and so on.
2. Call methods provided by the platform implementation through the `platform` field on the class, such as
   `WebViewController.platform`, `WebViewWidget.platform`, and so on.

The following example shows how to set additional parameters for iOS/macOS and Android on `WebViewController`.

```dart
late final PlatformWebViewControllerCreationParams params;
if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  params = WebKitWebViewControllerCreationParams(
    allowsInlineMediaPlayback: true,
    mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
  );
} else {
  params = const PlatformWebViewControllerCreationParams();
}

final controller = WebViewController.fromPlatformCreationParams(params);

if (controller.platform is AndroidWebViewController) {
  AndroidWebViewController.enableDebugging(true);
  (controller.platform as AndroidWebViewController)
      .setMediaPlaybackRequiresUserGesture(false);
}
```

For more information about Android platform features, see:
https://pub.dev/documentation/webview_flutter_android/latest/webview_flutter_android/webview_flutter_android-library.html

For more information about iOS/macOS platform features, see:
https://pub.dev/documentation/webview_flutter_wkwebview/latest/webview_flutter_wkwebview/webview_flutter_wkwebview-library.html

### Enable Material Components for Android

If you want users to use Material Components when interacting with input controls in WebView, please follow the steps in [Enable Material Components](https://docs.flutter.dev/deployment/android#enable-material-components).

### Set Custom Request Headers for POST Requests

Currently, when making POST requests through `WebViewController.loadRequest` on Android, setting custom request headers is not yet supported. If you need this capability, one workaround is to make the request manually and then load the response content through `loadHtmlString`.

### Linux Setup

Linux apps need one small code change so `WebViewWidget` can load correctly inside a `GtkOverlay`.

Edit `linux/runner/my_application.cc` in your project:

1. Add this function near the top:

```cc
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}
```

2. Find this code:

```cpp
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  gtk_widget_show(GTK_WIDGET(window));

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
```

Replace it with:

```cpp
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));

  GtkWidget* overlay = gtk_overlay_new();
  gtk_widget_show(overlay);
  gtk_container_add(GTK_CONTAINER(overlay), GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), overlay);

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
```

### Known Limitations

* Some APIs are missing on the macOS platform.
* The Web platform is limited by browser security policies.
