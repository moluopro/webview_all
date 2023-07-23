// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebviewMobile extends StatefulWidget {
  final String url;
  final Color backgroundColor;
  final JavaScriptMode javaScriptMode;

  const WebviewMobile(
      {super.key,
      required this.url,
      required this.backgroundColor,
      required this.javaScriptMode});

  @override
  State<WebviewMobile> createState() => _WebviewMobileState(
      url: url,
      backgroundColor: backgroundColor,
      javaScriptMode: javaScriptMode);
}

class _WebviewMobileState extends State<WebviewMobile> {
  final String url;
  final Color backgroundColor;
  final JavaScriptMode javaScriptMode;

  _WebviewMobileState(
      {required this.url,
      required this.backgroundColor,
      required this.javaScriptMode});

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    // if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    //   params = WebKitWebViewControllerCreationParams(
    //     allowsInlineMediaPlayback: true,
    //     mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    //   );
    // } else {
    //   params = const PlatformWebViewControllerCreationParams();
    // }
    params = const PlatformWebViewControllerCreationParams();
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(javaScriptMode)
      ..setBackgroundColor(backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   debugPrint('blocking navigation to ${request.url}');
            //   return NavigationDecision.prevent;
            // }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(url));

    // #docregion platform_features
    // if (controller.platform is AndroidWebViewController) {
    // AndroidWebViewController.enableDebugging(true);
    //   (controller.platform as AndroidWebViewController)
    //       .setMediaPlaybackRequiresUserGesture(false);
    // }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
