/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'package:abutil/abutil.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewFlutter extends StatefulWidget {
  final String url;
  final Color backgroundColor;
  final JavaScriptMode javaScriptMode;

  const WebviewFlutter({
    super.key,
    required this.url,
    required this.backgroundColor,
    required this.javaScriptMode,
  });

  @override
  State<WebviewFlutter> createState() => _WebviewFlutterState();
}

class _WebviewFlutterState extends State<WebviewFlutter> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final params = const PlatformWebViewControllerCreationParams();
    final controller = WebViewController.fromPlatformCreationParams(params);

    if (!isMacOS()) {
      controller.setBackgroundColor(widget.backgroundColor);
    }

    controller
      ..setJavaScriptMode(widget.javaScriptMode)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Web resource error:
  Code: ${error.errorCode}
  Description: ${error.description}
  ErrorType: ${error.errorType}
  IsMainFrame: ${error.isForMainFrame}
''');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to ${request.url}');
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
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
