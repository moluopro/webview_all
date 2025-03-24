/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'package:flutter/material.dart';

import 'webview_flutter.dart';
import 'package:webview_all/src/webview/webview_linux.dart';
import 'package:webview_all/src/webview/webview_windows.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'webview_web.dart' if (dart.library.io) "webview_web_vain.dart";

import 'package:abutil/abutil.dart';

class Webview extends StatelessWidget {
  final String url;

  const Webview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (isMobile() || isMacOS()) {
      return WebviewFlutter(
          url: url,
          backgroundColor: const Color(0x00000000),
          javaScriptMode: JavaScriptMode.unrestricted);
    } else if (isWeb()) {
      return WebviewWeb(url: url);
    } else if (isWindows()) {
      return WebviewWindows(
          url: url,
          backgroundColor: const Color(0x00000000),
          javaScriptMode: JavaScriptMode.unrestricted);
    } else if (isLinux()) {
      return WebviewLinux(url: url);
    } else {
      return const SizedBox.expand();
    }
  }
}
