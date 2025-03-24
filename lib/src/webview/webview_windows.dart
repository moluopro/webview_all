/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'package:flutter/material.dart';

import 'package:webview_windows/webview_windows.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class WebviewWindows extends StatefulWidget {
  final String url;
  final Color backgroundColor;
  final JavaScriptMode javaScriptMode;

  const WebviewWindows({
    super.key,
    required this.url,
    required this.backgroundColor,
    required this.javaScriptMode,
  });

  @override
  State<WebviewWindows> createState() => _WebviewFlutterState();
}

class _WebviewFlutterState extends State<WebviewWindows> {
  late final WebviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebviewController();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await _controller.initialize();

    await _controller.setBackgroundColor(widget.backgroundColor);
    await _controller.loadUrl(widget.url);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Webview(
      _controller,
    );
  }
}
