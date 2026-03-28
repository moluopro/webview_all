// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'webview.dart' as legacy;

/// Creation parameters for [WindowsWebViewCookieManager].
class WindowsWebViewCookieManagerCreationParams
    extends PlatformWebViewCookieManagerCreationParams {
  /// Creates a new [WindowsWebViewCookieManagerCreationParams].
  const WindowsWebViewCookieManagerCreationParams();

  /// Creates a [WindowsWebViewCookieManagerCreationParams] from generic params.
  const WindowsWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
    PlatformWebViewCookieManagerCreationParams params,
  );
}

/// Cookie manager implementation for Windows.
class WindowsWebViewCookieManager extends PlatformWebViewCookieManager {
  /// Creates a [WindowsWebViewCookieManager].
  WindowsWebViewCookieManager(PlatformWebViewCookieManagerCreationParams params)
    : super.implementation(
        params is WindowsWebViewCookieManagerCreationParams
            ? params
            : WindowsWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
                params,
              ),
      );

  @override
  Future<bool> clearCookies() async {
    final controller = legacy.WebviewController();
    await controller.initialize();
    await controller.clearCookies();
    await controller.dispose();
    return true;
  }

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    throw UnsupportedError(
      'Setting cookies is not yet supported by webview_all_windows.',
    );
  }

  @override
  Future<List<WebViewCookie>> getCookies(Uri url) async {
    return <WebViewCookie>[];
  }
}
