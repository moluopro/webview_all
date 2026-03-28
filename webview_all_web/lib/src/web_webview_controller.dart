// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'content_type.dart';
import 'http_request_factory.dart';
import 'web_navigation_delegate.dart';

/// An implementation of [PlatformWebViewControllerCreationParams] using Flutter
/// for Web API.
@immutable
class WebWebViewControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  /// Creates a new [WebWebViewControllerCreationParams] instance.
  WebWebViewControllerCreationParams({
    @visibleForTesting this.httpRequestFactory = const HttpRequestFactory(),
  }) : super();

  /// Creates a [WebWebViewControllerCreationParams] instance based on [PlatformWebViewControllerCreationParams].
  WebWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    PlatformWebViewControllerCreationParams params, {
    @visibleForTesting
    HttpRequestFactory httpRequestFactory = const HttpRequestFactory(),
  }) : this(httpRequestFactory: httpRequestFactory);

  static int _nextIFrameId = 0;

  /// Handles creating and sending URL requests.
  final HttpRequestFactory httpRequestFactory;

  /// The underlying element used as the WebView.
  @visibleForTesting
  final web.HTMLIFrameElement iFrame = web.HTMLIFrameElement()
    ..id = 'webView${_nextIFrameId++}'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none';
}

/// An implementation of [PlatformWebViewController] using Flutter for Web API.
class WebWebViewController extends PlatformWebViewController {
  /// Constructs a [WebWebViewController].
  WebWebViewController(PlatformWebViewControllerCreationParams params)
    : super.implementation(
        params is WebWebViewControllerCreationParams
            ? params
            : WebWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                params,
              ),
      ) {
    _webWebViewParams.iFrame.onLoad.listen((_) {
      final String? resolvedUrl = _tryReadCurrentFrameUrl() ?? _currentUrl;
      if (resolvedUrl != null) {
        _currentUrl = resolvedUrl;
        _navigationDelegate?.onUrlChange?.call(UrlChange(url: resolvedUrl));
        _navigationDelegate?.onPageFinished?.call(resolvedUrl);
      }
      _navigationDelegate?.onProgress?.call(100);
      _lastLoadedType = _NavigationLoadType.finished;
    });
  }

  WebWebViewControllerCreationParams get _webWebViewParams =>
      params as WebWebViewControllerCreationParams;

  final List<String> _history = <String>[];
  int _historyIndex = -1;
  String? _currentUrl;
  String? _userAgentOverride;
  WebNavigationDelegate? _navigationDelegate;
  _NavigationLoadType _lastLoadedType = _NavigationLoadType.none;

  @override
  Future<void> loadFile(String absoluteFilePath) {
    throw UnsupportedError(
      'loadFile is not supported on web. Use loadFlutterAsset or '
      'loadHtmlString instead.',
    );
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    final String assetUrl = Uri.base.resolve(key).toString();
    await _loadUrl(assetUrl, updateHistory: true);
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    _navigationDelegate?.onPageStarted?.call(baseUrl ?? 'about:blank');
    _navigationDelegate?.onProgress?.call(0);
    _currentUrl = baseUrl ?? 'about:blank';
    _lastLoadedType = _NavigationLoadType.html;
    _webWebViewParams.iFrame.src = Uri.dataFromString(
      _injectBaseUrl(html, baseUrl),
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    if (!params.uri.hasScheme) {
      throw ArgumentError(
        'LoadRequestParams#uri is required to have a scheme.',
      );
    }

    if (params.headers.isEmpty &&
        (params.body == null || params.body!.isEmpty) &&
        params.method == LoadRequestMethod.get) {
      await _loadUrl(params.uri.toString(), updateHistory: true);
    } else {
      await _updateIFrameFromXhr(params);
    }
  }

  @override
  Future<String?> currentUrl() async {
    return _currentUrl;
  }

  @override
  Future<bool> canGoBack() async {
    return _historyIndex > 0;
  }

  @override
  Future<bool> canGoForward() async {
    return _historyIndex >= 0 && _historyIndex < _history.length - 1;
  }

  @override
  Future<void> goBack() async {
    if (!await canGoBack()) {
      return;
    }
    _historyIndex -= 1;
    await _loadUrl(_history[_historyIndex], updateHistory: false);
  }

  @override
  Future<void> goForward() async {
    if (!await canGoForward()) {
      return;
    }
    _historyIndex += 1;
    await _loadUrl(_history[_historyIndex], updateHistory: false);
  }

  @override
  Future<void> reload() async {
    if (_lastLoadedType == _NavigationLoadType.html) {
      _webWebViewParams.iFrame.src = _webWebViewParams.iFrame.src;
      return;
    }

    if (_currentUrl != null) {
      await _loadUrl(_currentUrl!, updateHistory: false);
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final web.CacheStorage cacheStorage = web.window.caches;
      final JSArray<JSString> keys = await cacheStorage.keys().toDart;
      for (final JSString key in keys.toDart) {
        await cacheStorage.delete(key.toDart).toDart;
      }
    } catch (_) {
      // Best-effort only for the host origin.
    }
  }

  @override
  Future<void> clearLocalStorage() async {
    try {
      web.window.localStorage.clear();
      web.window.sessionStorage.clear();
    } catch (_) {
      // Best-effort only for the host origin.
    }
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    _navigationDelegate = handler as WebNavigationDelegate;
  }

  @override
  Future<Offset> getScrollPosition() async {
    throw UnsupportedError(
      'Reading scroll position is not supported for the web iframe implementation.',
    );
  }

  @override
  Future<void> scrollTo(int x, int y) async {
    throw UnsupportedError(
      'Scrolling iframe content is not supported for cross-origin pages on web.',
    );
  }

  @override
  Future<void> scrollBy(int x, int y) async {
    throw UnsupportedError(
      'Scrolling iframe content is not supported for cross-origin pages on web.',
    );
  }

  @override
  Future<void> enableZoom(bool enabled) async {
    // Browser zoom is controlled by the user agent, not the iframe.
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    _webWebViewParams.iFrame.style.backgroundColor = _cssColorFrom(color);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    if (javaScriptMode == JavaScriptMode.unrestricted) {
      return;
    }

    throw UnsupportedError(
      'Disabling JavaScript is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setUserAgent(String? userAgent) async {
    if (userAgent == null) {
      _userAgentOverride = null;
      return;
    }

    _userAgentOverride = userAgent;
    throw UnsupportedError(
      'Overriding the user agent is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<String?> getUserAgent() async {
    return _userAgentOverride ?? web.window.navigator.userAgent;
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    throw UnsupportedError(
      'Running JavaScript inside an iframe is not supported for arbitrary web pages.',
    );
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) {
    throw UnsupportedError(
      'Running JavaScript inside an iframe is not supported for arbitrary web pages.',
    );
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) {
    throw UnsupportedError(
      'JavaScript channels are not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<String?> getTitle() async {
    try {
      return _webWebViewParams.iFrame.contentDocument?.title;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) async {}

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) async {}

  @override
  bool supportsSetScrollBarsEnabled() {
    return false;
  }

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) {
    throw UnsupportedError(
      'Console message forwarding is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)?
    onScrollPositionChange,
  ) async {}

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request)
    onJavaScriptAlertDialog,
  ) {
    throw UnsupportedError(
      'JavaScript dialog interception is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request)
    onJavaScriptConfirmDialog,
  ) {
    throw UnsupportedError(
      'JavaScript dialog interception is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request)
    onJavaScriptTextInputDialog,
  ) {
    throw UnsupportedError(
      'JavaScript dialog interception is not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) {
    throw UnsupportedError(
      'Permission requests are not supported by the web iframe implementation.',
    );
  }

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) async {}

  Future<void> _loadUrl(String url, {required bool updateHistory}) async {
    if (!await _shouldNavigate(url)) {
      return;
    }

    _currentUrl = url;
    _navigationDelegate?.onPageStarted?.call(url);
    _navigationDelegate?.onProgress?.call(0);
    _navigationDelegate?.onUrlChange?.call(UrlChange(url: url));

    if (updateHistory) {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(url);
      _historyIndex = _history.length - 1;
    }

    _lastLoadedType = _NavigationLoadType.url;
    _webWebViewParams.iFrame.src = url;
  }

  Future<bool> _shouldNavigate(String url) async {
    final NavigationRequestCallback? callback =
        _navigationDelegate?.onNavigationRequest;
    if (callback == null) {
      return true;
    }

    final NavigationDecision decision = await callback(
      NavigationRequest(url: url, isMainFrame: true),
    );
    return decision == NavigationDecision.navigate;
  }

  /// Performs an AJAX request defined by [params].
  Future<void> _updateIFrameFromXhr(LoadRequestParams params) async {
    if (!await _shouldNavigate(params.uri.toString())) {
      return;
    }

    _currentUrl = params.uri.toString();
    _navigationDelegate?.onPageStarted?.call(_currentUrl!);
    _navigationDelegate?.onProgress?.call(0);
    _navigationDelegate?.onUrlChange?.call(UrlChange(url: _currentUrl));

    final response =
        await _webWebViewParams.httpRequestFactory.request(
              params.uri.toString(),
              method: params.method.serialize(),
              requestHeaders: params.headers,
              sendData: params.body,
            )
            as web.Response;

    if (response.status >= 400) {
      _navigationDelegate?.onHttpError?.call(
        HttpResponseError(
          response: WebResourceResponse(
            uri: params.uri,
            statusCode: response.status,
          ),
        ),
      );
    }

    final String header = response.headers.get('content-type') ?? 'text/html';
    final contentType = ContentType.parse(header);
    final Encoding encoding = Encoding.getByName(contentType.charset) ?? utf8;

    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(params.uri.toString());
    _historyIndex = _history.length - 1;

    _lastLoadedType = _NavigationLoadType.html;
    _webWebViewParams.iFrame.src = Uri.dataFromString(
      (await response.text().toDart).toDart,
      mimeType: contentType.mimeType,
      encoding: encoding,
    ).toString();
  }

  String _injectBaseUrl(String html, String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) {
      return html;
    }

    final String baseTag = '<base href="$baseUrl">';
    final RegExp headExp = RegExp(r'<head[^>]*>', caseSensitive: false);
    final Match? match = headExp.firstMatch(html);
    if (match != null) {
      return html.replaceRange(match.end, match.end, baseTag);
    }
    return '<head>$baseTag</head>$html';
  }

  String? _tryReadCurrentFrameUrl() {
    try {
      return _webWebViewParams.iFrame.contentWindow?.location.href;
    } catch (_) {
      return _currentUrl;
    }
  }

  String _cssColorFrom(Color color) {
    final int alpha = color.alpha;
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;
    return 'rgba($red, $green, $blue, ${alpha / 255})';
  }
}

enum _NavigationLoadType { none, url, html, finished }

/// An implementation of [PlatformWebViewWidget] using Flutter the for Web API.
class WebWebViewWidget extends PlatformWebViewWidget {
  /// Constructs a [WebWebViewWidget].
  WebWebViewWidget(PlatformWebViewWidgetCreationParams params)
    : super.implementation(params) {
    final controller = params.controller as WebWebViewController;
    ui_web.platformViewRegistry.registerViewFactory(
      controller._webWebViewParams.iFrame.id,
      (int viewId) => controller._webWebViewParams.iFrame,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: params.key,
      viewType: (params.controller as WebWebViewController)
          ._webWebViewParams
          .iFrame
          .id,
    );
  }
}
