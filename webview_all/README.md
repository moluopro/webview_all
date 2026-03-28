# WebView All

A WebView component that supports all Flutter platforms.

- On iOS, the WebView component is based on [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).
- On Android, the WebView component is based on [WebView](https://developer.android.com/reference/android/webkit/WebView).
- On Windows, the WebView component is based on [WebView2](https://developer.microsoft.com/microsoft-edge/webview2/).
- On Linux, the WebView component is based on [WebKitGTK](https://webkitgtk.org/).

|             | Android | iOS   | macOS  | Windows |
|-------------|---------|-------|--------|---------|
| **Support** | SDK 24+ | 13.0+ | 10.15+ | WebView2 |


## Usage

You can now display a WebView in the following way:

1. Instantiate a `WebViewController`:

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        // Update the loading progress bar.
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

2. Pass the controller to `WebViewWidget`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: controller),
  );
}

```

For more details, refer to the Dart documentation for [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
and [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html).


## Platform Features

Many classes provide subclasses or underlying platform implementations so that platform-specific capabilities can be accessed.

To access platform-specific features, first add the corresponding platform implementation packages to your app or package:

* **Android**: [webview_flutter_android](https://pub.dev/packages/webview_flutter_android/install)
* **iOS/macOS**: [webview_flutter_wkwebview](https://pub.dev/packages/webview_flutter_wkwebview/install)

Then import the corresponding platform implementation packages in your app or package:

```dart
// Import Android platform features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import iOS/macOS platform features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
```

After that, additional capabilities can be accessed through the platform implementations.  
[WebViewController], [WebViewWidget], [NavigationDelegate], and [WebViewCookieManager]
all delegate their functionality to implementation classes provided by the current platform. Below are two common ways to access them, followed by an example.

1. Pass the creation params class provided by the platform implementation to a `fromPlatformCreationParams`
   constructor, such as `WebViewController.fromPlatformCreationParams`
   and `WebViewWidget.fromPlatformCreationParams`.
2. Call methods provided by the platform implementation through the `platform` field on the class,
   such as `WebViewController.platform` and `WebViewWidget.platform`.

The following example shows how to set additional iOS/macOS and Android parameters for `WebViewController`.

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

If you want users to use Material Components when interacting with input controls in the WebView, follow the steps in the [Enable Material Components instructions](https://docs.flutter.dev/deployment/android#enable-material-components).

### Set Custom Headers for POST Requests

Currently, when initiating a POST request through `WebViewController.loadRequest` on Android, setting custom headers is not supported yet. If you need this capability, one workaround is to make the request manually and then load the response content using `loadHtmlString`.

### Known Limitations

* Some APIs are missing on the macOS platform.
* Only a small subset of APIs is implemented on the web platform.
* The Linux platform is still under development and is not available yet.
