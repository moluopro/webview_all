/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'package:flutter/material.dart';
import 'package:webview_all_cef/webview_cef.dart';

class WebviewLinux extends StatefulWidget {
  final String url;

  const WebviewLinux({super.key, required this.url});

  @override
  State<WebviewLinux> createState() => _WebviewFlutterState();
}

class _WebviewFlutterState extends State<WebviewLinux> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView();
    initPlatformState();
  }

  @override
  void dispose() {
    _controller.dispose();
    WebviewManager().quit();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    await WebviewManager().initialize(userAgent: "test/userAgent");
    await _controller.loadUrl(widget.url);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _controller.webviewWidget;
  }
}
