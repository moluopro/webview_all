# WebView All

支持所有Flutter平台的Webview组件。

|     系统     | **支持情况** | **技术实现** |
|-------------|--------------|--------------|
|Android|SDK 24+|[WebView](https://developer.android.com/reference/android/webkit/WebView)|
|iOS|13.0+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Windows|Win10 1809+|[WebView2](https://developer.microsoft.com/microsoft-edge/webview2)|
|macOS|10.15+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Linux|webkit2gtk-4.1|[WebKitGTK](https://webkitgtk.org)|
|Web|Any|[js-interop](https://dart.dev/interop/js-interop)|


## 用法

现在你可以按下面的方式显示一个 WebView：

1. 实例化一个 `WebViewController`:

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        // 更新加载进度条
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

2. 将 controller 传给 `WebViewWidget`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: controller),
  );
}

```

更多细节请参考 [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
和 [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html) 的 Dart 文档。


## 平台特性

许多类都提供了子类，或提供了底层平台实现，以便访问平台专属能力。

如果要访问平台特性，请先将对应的平台实现包添加到你的应用或包中：

* **Android**: [webview_flutter_android](https://pub.dev/packages/webview_flutter_android/install)
* **iOS/macOS**: [webview_flutter_wkwebview](https://pub.dev/packages/webview_flutter_wkwebview/install)

然后，在你的应用或包中导入对应的平台实现包：

```dart
// 导入 Android 平台特性。
import 'package:webview_flutter_android/webview_flutter_android.dart';
// 导入 iOS/macOS 平台特性。
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
```

之后，就可以通过平台实现访问额外能力。  
[WebViewController]、[WebViewWidget]、[NavigationDelegate] 和 [WebViewCookieManager]
都会将其功能委托给当前平台提供的实现类。下面是两种常见访问方式，后面也附了示例。

1. 将平台实现提供的 creation params 类传给 `fromPlatformCreationParams`
   构造函数，例如 `WebViewController.fromPlatformCreationParams`、
   `WebViewWidget.fromPlatformCreationParams` 等。
2. 通过类上的 `platform` 字段调用平台实现提供的方法，例如
   `WebViewController.platform`、`WebViewWidget.platform` 等。

下面的示例展示了如何给 `WebViewController` 设置 iOS/macOS 和 Android 的额外参数。

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

Android 平台特性的更多说明请参考：
https://pub.dev/documentation/webview_flutter_android/latest/webview_flutter_android/webview_flutter_android-library.html

iOS/macOS 平台特性的更多说明请参考：
https://pub.dev/documentation/webview_flutter_wkwebview/latest/webview_flutter_wkwebview/webview_flutter_wkwebview-library.html

### 为 Android 启用 Material Components

如果你希望用户在 WebView 中与输入控件交互时使用 Material Components，请按照 [启用 Material Components 说明](https://docs.flutter.dev/deployment/android#enable-material-components) 中的步骤进行配置。

### 为 POST 请求设置自定义请求头

目前，在 Android 上通过 `WebViewController.loadRequest` 发起 POST 请求时，还不支持设置自定义请求头。如果你需要这个能力，一种变通方案是手动发起请求，然后再通过 `loadHtmlString` 加载响应内容。

### Linux 设置

Linux平台需要修改代码使得 `WebViewWidget` 能在 `GtkOverlay` 正确加载。

编辑您项目里的 `linux/runner/my_application.cc` 即可：

1. 在靠前的位置添加函数:

```cc
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}
```

2. 找到以下代码:

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

替换为:

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
```

### 已知的限制

* macOS 平台缺失了部分API。
* Web 平台仅实现了少部分API。
