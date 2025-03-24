/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class WebviewWeb extends StatefulWidget {
  final String url;

  const WebviewWeb({super.key, required this.url});

  @override
  State<WebviewWeb> createState() => _WebviewWebState(url: url);
}

class _WebviewWebState extends State<WebviewWeb> {
  late String url;

  _WebviewWebState({required this.url});

  @override
  void initState() {
    super.initState();
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )..loadRequest(
        LoadRequestParams(
          uri: Uri.parse(url),
        ),
      );
    return PlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams(controller: controller),
    ).build(context);
  }
}
