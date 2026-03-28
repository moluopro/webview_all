# WebView All

A WebView component that supports all Flutter platforms.

|     Platform     | **Support** | **Implementation** |
|-------------|--------------|--------------|
|Android|SDK 24+|[WebView](https://developer.android.com/reference/android/webkit/WebView)|
|iOS|13.0+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Windows|Win10 1809+|[WebView2](https://developer.microsoft.com/microsoft-edge/webview2)|
|macOS|10.15+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Linux|webkit2gtk-4.1|[WebKitGTK](https://webkitgtk.org)|
|Web|Any|[js-interop](https://dart.dev/interop/js-interop)|


## Usage

You can now display a WebView in the following way:

1. Instantiate a `WebViewController`:

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        // Update the loading progress bar
      },
      onPageStarted: (String url) {},
      onPageFinished: (String url) {},
      onHttpError: (HttpResponseError error) {},
      onWebResourceError: (WebResourceError error) {},
      onNavigationRequest: (NavigationRequest request) {
        if (request.url.startsWith('https://www.bilibili.com')) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  )
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

For more details, please refer to the Dart documentation for [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
and [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html).


## Platform Features

Many classes provide subclasses, or expose the underlying platform implementation, so that you can access platform-specific capabilities.

If you want to access platform features, first add the corresponding platform implementation package to your app or package:

* **Android**: [webview_flutter_android](https://pub.dev/packages/webview_flutter_android/install)
* **iOS/macOS**: [webview_flutter_wkwebview](https://pub.dev/packages/webview_flutter_wkwebview/install)

Then, import the corresponding platform implementation package in your app or package:

```dart
// Import Android platform features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import iOS/macOS platform features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
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

Linux apps need one small change so `WebViewWidget` can be hosted in a `GtkOverlay`.

Edit `linux/runner/my_application.cc`: 

1. Add:

```cc
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}
```

2. Then replace the default runner part:

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

with:

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
* Only a small subset of APIs is implemented on the Web platform.
