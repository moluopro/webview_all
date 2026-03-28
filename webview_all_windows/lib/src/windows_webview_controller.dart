// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'enums.dart' as legacy_types;
import 'webview.dart' as legacy_webview;

/// Windows-specific policy for popup windows.
enum WindowsPopupWindowPolicy {
  /// Allow popups to open separate windows.
  allow,

  /// Suppress popup windows.
  deny,

  /// Open popup content in the current window.
  sameWindow,
}

/// Creation parameters for [WindowsWebViewController].
@immutable
class WindowsWebViewControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  /// Creates a new [WindowsWebViewControllerCreationParams].
  const WindowsWebViewControllerCreationParams({
    this.popupWindowPolicy = WindowsPopupWindowPolicy.sameWindow,
  });

  /// Creates a [WindowsWebViewControllerCreationParams] from generic params.
  const WindowsWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    PlatformWebViewControllerCreationParams params, {
    this.popupWindowPolicy = WindowsPopupWindowPolicy.sameWindow,
  });

  /// How popup windows should be handled.
  final WindowsPopupWindowPolicy popupWindowPolicy;
}

/// Windows-specific creation parameters for [WindowsWebViewWidget].
@immutable
class WindowsWebViewWidgetCreationParams
    extends PlatformWebViewWidgetCreationParams {
  /// Creates a new [WindowsWebViewWidgetCreationParams].
  const WindowsWebViewWidgetCreationParams({
    super.key,
    required super.controller,
    super.layoutDirection,
    super.gestureRecognizers,
    this.scaleFactor,
    this.filterQuality = FilterQuality.none,
  });

  /// Creates a [WindowsWebViewWidgetCreationParams] from generic params.
  WindowsWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
    PlatformWebViewWidgetCreationParams params, {
    double? scaleFactor,
    FilterQuality filterQuality = FilterQuality.none,
  }) : this(
         key: params.key,
         controller: params.controller,
         layoutDirection: params.layoutDirection,
         gestureRecognizers: params.gestureRecognizers,
         scaleFactor: scaleFactor,
         filterQuality: filterQuality,
       );

  /// Optional rasterization scale factor.
  final double? scaleFactor;

  /// Filter quality for the underlying texture.
  final FilterQuality filterQuality;
}

/// Creation parameters for [WindowsNavigationDelegate].
@immutable
class WindowsNavigationDelegateCreationParams
    extends PlatformNavigationDelegateCreationParams {
  /// Creates a new [WindowsNavigationDelegateCreationParams].
  const WindowsNavigationDelegateCreationParams();

  /// Creates a [WindowsNavigationDelegateCreationParams] from generic params.
  const WindowsNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
    PlatformNavigationDelegateCreationParams params,
  );
}

/// A WebView2-backed implementation of [PlatformWebViewController].
class WindowsWebViewController extends PlatformWebViewController {
  /// Creates a [WindowsWebViewController].
  WindowsWebViewController(PlatformWebViewControllerCreationParams params)
    : _webviewController = legacy_webview.WebviewController(),
      super.implementation(
        params is WindowsWebViewControllerCreationParams
            ? params
            : WindowsWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                params,
              ),
      ) {
    _initializationFuture = _initialize();
  }

  final legacy_webview.WebviewController _webviewController;
  final Map<String, JavaScriptChannelParams> _javaScriptChannelParams =
      <String, JavaScriptChannelParams>{};
  final Map<String, String> _javaScriptChannelScriptIds = <String, String>{};
  final Map<String, String> _virtualHostMappings = <String, String>{};
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  Future<void>? _initializationFuture;
  WindowsNavigationDelegate? _currentNavigationDelegate;
  String? _currentUrl;
  String? _pageStartedUrl;
  String? _title;
  String? _userAgent;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _scrollBridgeInstalled = false;
  String? _consoleBridgeScriptId;

  void Function(JavaScriptConsoleMessage)? _onConsoleMessageCallback;
  void Function(ScrollPositionChange)? _onScrollPositionChangeCallback;

  WindowsWebViewControllerCreationParams get _windowsParams =>
      params as WindowsWebViewControllerCreationParams;

  static const String _channelMessageType = '__windows_webview_all_type';
  static const String _javaScriptChannelMessageType = 'javascriptChannel';
  static const String _consoleMessageType = 'consoleMessage';
  static const String _scrollMessageType = 'scrollPositionChange';

  /// Explicitly initializes the shared WebView2 environment.
  static Future<void> initializeEnvironment({
    String? userDataPath,
    String? browserExePath,
    String? additionalArguments,
  }) {
    return legacy_webview.WebviewController.initializeEnvironment(
      userDataPath: userDataPath,
      browserExePath: browserExePath,
      additionalArguments: additionalArguments,
    );
  }

  /// Returns the installed WebView2 runtime version, if available.
  static Future<String?> getWebViewVersion() {
    return legacy_webview.WebviewController.getWebViewVersion();
  }

  Future<void> _initialize() async {
    await _webviewController.initialize();
    await _webviewController.setPopupWindowPolicy(
      switch (_windowsParams.popupWindowPolicy) {
        WindowsPopupWindowPolicy.allow =>
          legacy_types.WebviewPopupWindowPolicy.allow,
        WindowsPopupWindowPolicy.deny =>
          legacy_types.WebviewPopupWindowPolicy.deny,
        WindowsPopupWindowPolicy.sameWindow =>
          legacy_types.WebviewPopupWindowPolicy.sameWindow,
      },
    );

    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _webviewController.url.listen(_handleUrlChanged),
      _webviewController.title.listen((String title) {
        _title = title;
      }),
      _webviewController.historyChanged.listen((
        legacy_webview.HistoryChanged value,
      ) {
        _canGoBack = value.canGoBack;
        _canGoForward = value.canGoForward;
      }),
      _webviewController.loadingState.listen(_handleLoadingStateChanged),
      _webviewController.onLoadError.listen(_handleLoadError),
      _webviewController.webMessage.listen(_handleWebMessage),
    ]);
  }

  Future<void> _ensureInitialized() async {
    await _initializationFuture!;
  }

  void _handleUrlChanged(String url) {
    _currentUrl = url;
    _pageStartedUrl ??= url;
    _currentNavigationDelegate?._onUrlChange?.call(UrlChange(url: url));
  }

  void _handleLoadingStateChanged(legacy_types.LoadingState state) {
    switch (state) {
      case legacy_types.LoadingState.none:
        break;
      case legacy_types.LoadingState.loading:
        final url = _currentUrl ?? _pageStartedUrl ?? '';
        _pageStartedUrl = url;
        _currentNavigationDelegate?._onProgress?.call(0);
        _currentNavigationDelegate?._onPageStarted?.call(url);
        break;
      case legacy_types.LoadingState.navigationCompleted:
        final url = _currentUrl ?? _pageStartedUrl ?? '';
        _currentNavigationDelegate?._onProgress?.call(100);
        _currentNavigationDelegate?._onPageFinished?.call(url);
        _pageStartedUrl = null;
        break;
    }
  }

  void _handleLoadError(legacy_types.WebErrorStatus status) {
    _currentNavigationDelegate?._onWebResourceError?.call(
      WindowsWebResourceError(status, url: _currentUrl, isForMainFrame: true),
    );
  }

  void _handleWebMessage(dynamic message) {
    if (message is! Map) {
      return;
    }

    final type = message[_channelMessageType] as String?;
    switch (type) {
      case _javaScriptChannelMessageType:
        final channelName = message['channelName'] as String?;
        final params = channelName == null
            ? null
            : _javaScriptChannelParams[channelName];
        if (params != null) {
          params.onMessageReceived(
            JavaScriptMessage(message: '${message['message'] ?? ''}'),
          );
        }
        break;
      case _consoleMessageType:
        final callback = _onConsoleMessageCallback;
        if (callback != null) {
          callback(
            JavaScriptConsoleMessage(
              level: _parseJavaScriptLogLevel(message['level'] as String?),
              message: '${message['message'] ?? ''}',
            ),
          );
        }
        break;
      case _scrollMessageType:
        final callback = _onScrollPositionChangeCallback;
        if (callback != null) {
          callback(
            ScrollPositionChange(
              (message['x'] as num?)?.toDouble() ?? 0.0,
              (message['y'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  JavaScriptLogLevel _parseJavaScriptLogLevel(String? level) {
    switch (level) {
      case 'debug':
        return JavaScriptLogLevel.debug;
      case 'error':
        return JavaScriptLogLevel.error;
      case 'info':
        return JavaScriptLogLevel.info;
      case 'warning':
        return JavaScriptLogLevel.warning;
      default:
        return JavaScriptLogLevel.log;
    }
  }

  @override
  Future<void> loadFile(String absoluteFilePath) async {
    await _ensureInitialized();
    final file = File(absoluteFilePath);
    if (!file.existsSync()) {
      throw ArgumentError.value(
        absoluteFilePath,
        'absoluteFilePath',
        'File does not exist.',
      );
    }

    final folderPath = path.dirname(file.absolute.path);
    final fileName = path.basename(file.path);
    const host = 'app-file.webview.flutter.dev';
    final url = Uri.https(host, '/$fileName').toString();
    if (!await _shouldNavigate(url)) {
      return;
    }
    await _setVirtualHostMapping(host, folderPath);
    await _webviewController.loadUrl(url);
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    await _ensureInitialized();
    final assetPath = _resolveFlutterAssetPath(key);
    final file = File(assetPath);
    if (!file.existsSync()) {
      throw ArgumentError.value(key, 'key', 'Asset for key "$key" not found.');
    }

    final folderPath = path.dirname(assetPath);
    final fileName = path.basename(assetPath);
    const host = 'flutter-assets.webview.flutter.dev';
    final url = Uri.https(host, '/$fileName').toString();
    if (!await _shouldNavigate(url)) {
      return;
    }
    await _setVirtualHostMapping(host, folderPath);
    await _webviewController.loadUrl(url);
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    await _ensureInitialized();
    final content = baseUrl == null ? html : _injectBaseUrl(html, baseUrl);
    await _webviewController.loadStringContent(content);
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    await _ensureInitialized();
    if (!params.uri.hasScheme) {
      throw ArgumentError(
        'LoadRequestParams#uri is required to have a scheme.',
      );
    }

    if (params.method == LoadRequestMethod.get &&
        params.headers.isEmpty &&
        (params.body == null || params.body!.isEmpty)) {
      if (!await _shouldNavigate(params.uri.toString())) {
        return;
      }
      await _webviewController.loadUrl(params.uri.toString());
      return;
    }

    throw UnsupportedError(
      'Windows WebView2 currently only supports GET requests without custom '
      'headers or body through this plugin.',
    );
  }

  @override
  Future<String?> currentUrl() async {
    await _ensureInitialized();
    return _currentUrl;
  }

  @override
  Future<bool> canGoBack() async {
    await _ensureInitialized();
    return _canGoBack;
  }

  @override
  Future<bool> canGoForward() async {
    await _ensureInitialized();
    return _canGoForward;
  }

  @override
  Future<void> goBack() async {
    await _ensureInitialized();
    await _webviewController.goBack();
  }

  @override
  Future<void> goForward() async {
    await _ensureInitialized();
    await _webviewController.goForward();
  }

  @override
  Future<void> reload() async {
    await _ensureInitialized();
    await _webviewController.reload();
  }

  @override
  Future<void> clearCache() async {
    await _ensureInitialized();
    await _webviewController.clearCache();
  }

  @override
  Future<void> clearLocalStorage() async {
    await _ensureInitialized();
    await runJavaScript('''
      try {
        localStorage.clear();
        sessionStorage.clear();
      } catch (_) {}
      ''');
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    await _ensureInitialized();
    _currentNavigationDelegate = handler as WindowsNavigationDelegate;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    await _ensureInitialized();
    await _webviewController.executeScript(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    await _ensureInitialized();
    final dynamic result = await _webviewController.executeScript(javaScript);
    if (result == null) {
      throw ArgumentError(
        'The JavaScript returned `null` or `undefined`, which is unsupported.',
      );
    }
    return result as Object;
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    await _ensureInitialized();
    final name = javaScriptChannelParams.name;
    if (_javaScriptChannelParams.containsKey(name)) {
      throw ArgumentError(
        'A JavaScriptChannel with name `$name` already exists.',
      );
    }

    _javaScriptChannelParams[name] = javaScriptChannelParams;
    final script =
        '''
      window.$name = {
        postMessage: function(message) {
          window.chrome.webview.postMessage({
            "$_channelMessageType": "$_javaScriptChannelMessageType",
            "channelName": "$name",
            "message": String(message)
          });
        }
      };
    ''';
    final scriptId = await _webviewController
        .addScriptToExecuteOnDocumentCreated(script);
    if (scriptId != null) {
      _javaScriptChannelScriptIds[name] = scriptId;
    }
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    await _ensureInitialized();
    _javaScriptChannelParams.remove(javaScriptChannelName);
    final scriptId = _javaScriptChannelScriptIds.remove(javaScriptChannelName);
    if (scriptId != null) {
      await _webviewController.removeScriptToExecuteOnDocumentCreated(scriptId);
    }
  }

  @override
  Future<String?> getTitle() async {
    await _ensureInitialized();
    return _title;
  }

  @override
  Future<void> scrollTo(int x, int y) async {
    await runJavaScript('window.scrollTo($x, $y);');
  }

  @override
  Future<void> scrollBy(int x, int y) async {
    await runJavaScript('window.scrollBy($x, $y);');
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
  Future<Offset> getScrollPosition() async {
    final value = await runJavaScriptReturningResult(
      '({x: window.scrollX || window.pageXOffset || 0, '
      'y: window.scrollY || window.pageYOffset || 0})',
    );
    final position = value as Map<Object?, Object?>;
    return Offset(
      (position['x'] as num?)?.toDouble() ?? 0,
      (position['y'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<void> enableZoom(bool enabled) async {
    await _ensureInitialized();
    if (enabled) {
      await _webviewController.setZoomFactor(1.0);
      return;
    }

    await runJavaScript('''
      (function() {
        let viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
          viewport = document.createElement('meta');
          viewport.name = 'viewport';
          document.head.appendChild(viewport);
        }
        viewport.content =
            'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
      })();
      ''');
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    await _ensureInitialized();
    await _webviewController.setBackgroundColor(color);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    if (javaScriptMode == JavaScriptMode.unrestricted) {
      return;
    }
    throw UnsupportedError(
      'Windows WebView2 does not currently support disabling JavaScript in '
      'this plugin implementation.',
    );
  }

  @override
  Future<void> setUserAgent(String? userAgent) async {
    await _ensureInitialized();
    if (userAgent == null) {
      throw UnsupportedError(
        'Resetting the Windows user agent to the default value is not '
        'supported by this plugin implementation.',
      );
    }
    _userAgent = userAgent;
    await _webviewController.setUserAgent(userAgent);
  }

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    await _ensureInitialized();
    _webviewController.setPermissionRequestedDelegate((
      String url,
      legacy_types.WebviewPermissionKind permissionKind,
      bool isUserInitiated,
    ) async {
      final request = _WindowsWebViewPermissionRequest(
        types: _toPermissionTypes(permissionKind),
      );
      onPermissionRequest(request);
      return request.decision.future;
    });
  }

  @override
  Future<String?> getUserAgent() async {
    await _ensureInitialized();
    return _userAgent;
  }

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {
    await _ensureInitialized();
    _onConsoleMessageCallback = onConsoleMessage;
    if (_consoleBridgeScriptId != null) {
      return;
    }

    final script =
        '''
      (function() {
        if (window.__flutterWindowsConsoleHookInstalled) {
          return;
        }
        window.__flutterWindowsConsoleHookInstalled = true;
        function emit(level, args) {
          window.chrome.webview.postMessage({
            "$_channelMessageType": "$_consoleMessageType",
            "level": level,
            "message": Array.from(args).map(function(arg) {
              return typeof arg === 'string' ? arg : JSON.stringify(arg);
            }).join(' ')
          });
        }
        ['log', 'info', 'warn', 'error', 'debug'].forEach(function(level) {
          const original = console[level];
          console[level] = function() {
            emit(level === 'warn' ? 'warning' : level, arguments);
            if (original) {
              original.apply(console, arguments);
            }
          };
        });
      })();
    ''';
    _consoleBridgeScriptId = await _webviewController
        .addScriptToExecuteOnDocumentCreated(script);
  }

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)?
    onScrollPositionChange,
  ) async {
    await _ensureInitialized();
    _onScrollPositionChangeCallback = onScrollPositionChange;
    if (_scrollBridgeInstalled || onScrollPositionChange == null) {
      return;
    }

    _scrollBridgeInstalled = true;
    await _webviewController.addScriptToExecuteOnDocumentCreated('''
      (function() {
        if (window.__flutterWindowsScrollHookInstalled) {
          return;
        }
        window.__flutterWindowsScrollHookInstalled = true;
        window.addEventListener('scroll', function() {
          window.chrome.webview.postMessage({
            "$_channelMessageType": "$_scrollMessageType",
            "x": window.scrollX || window.pageXOffset || 0,
            "y": window.scrollY || window.pageYOffset || 0
          });
        }, { passive: true });
      })();
      ''');
  }

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request)
    onJavaScriptAlertDialog,
  ) async {
    throw UnsupportedError(
      'JavaScript alert dialog callbacks are not yet supported on Windows.',
    );
  }

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request)
    onJavaScriptConfirmDialog,
  ) async {
    throw UnsupportedError(
      'JavaScript confirm dialog callbacks are not yet supported on Windows.',
    );
  }

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request)
    onJavaScriptTextInputDialog,
  ) async {
    throw UnsupportedError(
      'JavaScript text input dialog callbacks are not yet supported on Windows.',
    );
  }

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) async {
    switch (mode) {
      case WebViewOverScrollMode.never:
        await runJavaScript('''
          (function() {
            document.documentElement.style.overscrollBehavior = 'none';
            document.body.style.overscrollBehavior = 'none';
          })();
          ''');
        break;
      case WebViewOverScrollMode.always:
      case WebViewOverScrollMode.ifContentScrolls:
        break;
    }
  }

  /// Opens the browser devtools for this WebView.
  Future<void> openDevTools() async {
    await _ensureInitialized();
    await _webviewController.openDevTools();
  }

  /// Suspends the WebView.
  Future<void> suspend() async {
    await _ensureInitialized();
    await _webviewController.suspend();
  }

  /// Resumes a suspended WebView.
  Future<void> resume() async {
    await _ensureInitialized();
    await _webviewController.resume();
  }

  /// Sets the popup policy for this WebView.
  Future<void> setPopupWindowPolicy(WindowsPopupWindowPolicy policy) async {
    await _ensureInitialized();
    await _webviewController.setPopupWindowPolicy(switch (policy) {
      WindowsPopupWindowPolicy.allow =>
        legacy_types.WebviewPopupWindowPolicy.allow,
      WindowsPopupWindowPolicy.deny =>
        legacy_types.WebviewPopupWindowPolicy.deny,
      WindowsPopupWindowPolicy.sameWindow =>
        legacy_types.WebviewPopupWindowPolicy.sameWindow,
    });
  }

  /// Sets the WebView2 zoom factor.
  Future<void> setZoomFactor(double zoomFactor) async {
    await _ensureInitialized();
    await _webviewController.setZoomFactor(zoomFactor);
  }

  /// Toggles whether the network cache is ignored for requests.
  Future<void> setCacheDisabled(bool disabled) async {
    await _ensureInitialized();
    await _webviewController.setCacheDisabled(disabled);
  }

  Future<void> _setVirtualHostMapping(String host, String folderPath) async {
    final normalizedPath = path.normalize(folderPath);
    if (_virtualHostMappings[host] == normalizedPath) {
      return;
    }

    _virtualHostMappings[host] = normalizedPath;
    await _webviewController.addVirtualHostNameMapping(
      host,
      normalizedPath,
      legacy_types.WebviewHostResourceAccessKind.allow,
    );
  }

  Future<bool> _shouldNavigate(String url) async {
    final callback = _currentNavigationDelegate?._onNavigationRequest;
    if (callback == null) {
      return true;
    }

    final decision = await callback(
      NavigationRequest(url: url, isMainFrame: true),
    );
    return decision == NavigationDecision.navigate;
  }

  String _injectBaseUrl(String html, String baseUrl) {
    final baseTag = '<base href="$baseUrl">';
    final headExp = RegExp(r'<head[^>]*>', caseSensitive: false);
    final match = headExp.firstMatch(html);
    if (match != null) {
      return html.replaceRange(match.end, match.end, baseTag);
    }
    return '<head>$baseTag</head>$html';
  }

  String _resolveFlutterAssetPath(String key) {
    return path.joinAll(<String>[
      path.dirname(Platform.resolvedExecutable),
      'data',
      'flutter_assets',
      ...key.split('/'),
    ]);
  }

  Set<WebViewPermissionResourceType> _toPermissionTypes(
    legacy_types.WebviewPermissionKind permissionKind,
  ) {
    switch (permissionKind) {
      case legacy_types.WebviewPermissionKind.camera:
        return <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.camera,
        };
      case legacy_types.WebviewPermissionKind.microphone:
        return <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.microphone,
        };
      default:
        return const <WebViewPermissionResourceType>{};
    }
  }
}

/// WebView widget implementation for Windows.
class WindowsWebViewWidget extends PlatformWebViewWidget {
  /// Creates a [WindowsWebViewWidget].
  WindowsWebViewWidget(PlatformWebViewWidgetCreationParams params)
    : super.implementation(
        params is WindowsWebViewWidgetCreationParams
            ? params
            : WindowsWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
                params,
              ),
      );

  WindowsWebViewWidgetCreationParams get _windowsParams =>
      params as WindowsWebViewWidgetCreationParams;

  @override
  Widget build(BuildContext context) {
    final controller = params.controller as WindowsWebViewController;
    return FutureBuilder<void>(
      future: controller._ensureInitialized(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        return KeyedSubtree(
          key: params.key,
          child: legacy_webview.Webview(
            controller._webviewController,
            scaleFactor: _windowsParams.scaleFactor,
            filterQuality: _windowsParams.filterQuality,
          ),
        );
      },
    );
  }
}

/// Windows implementation of [PlatformNavigationDelegate].
class WindowsNavigationDelegate extends PlatformNavigationDelegate {
  /// Creates a [WindowsNavigationDelegate].
  WindowsNavigationDelegate(PlatformNavigationDelegateCreationParams params)
    : super.implementation(
        params is WindowsNavigationDelegateCreationParams
            ? params
            : WindowsNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
                params,
              ),
      );

  PageEventCallback? _onPageFinished;
  PageEventCallback? _onPageStarted;
  ProgressCallback? _onProgress;
  WebResourceErrorCallback? _onWebResourceError;
  NavigationRequestCallback? _onNavigationRequest;
  UrlChangeCallback? _onUrlChange;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    _onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    _onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    _onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    // HTTP response callbacks are not surfaced by the current Windows backend.
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    _onProgress = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    _onWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
    _onUrlChange = onUrlChange;
  }

  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {
    // HTTP auth callbacks are not surfaced by the current Windows backend.
  }

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {
    // SSL auth callbacks are not surfaced by the current Windows backend.
  }
}

/// Windows error mapping for WebView2 load failures.
class WindowsWebResourceError extends WebResourceError {
  /// Creates a [WindowsWebResourceError].
  WindowsWebResourceError(
    legacy_types.WebErrorStatus status, {
    super.url,
    super.isForMainFrame,
  }) : super(
         errorCode: status.index,
         description: status.name,
         errorType: _toErrorType(status),
       );

  static WebResourceErrorType? _toErrorType(
    legacy_types.WebErrorStatus status,
  ) {
    switch (status) {
      case legacy_types.WebErrorStatus.WebErrorStatusTimeout:
        return WebResourceErrorType.timeout;
      case legacy_types.WebErrorStatus.WebErrorStatusCannotConnect:
      case legacy_types.WebErrorStatus.WebErrorStatusConnectionAborted:
      case legacy_types.WebErrorStatus.WebErrorStatusConnectionReset:
      case legacy_types.WebErrorStatus.WebErrorStatusServerUnreachable:
        return WebResourceErrorType.connect;
      case legacy_types.WebErrorStatus.WebErrorStatusDisconnected:
        return WebResourceErrorType.io;
      case legacy_types.WebErrorStatus.WebErrorStatusHostNameNotResolved:
        return WebResourceErrorType.hostLookup;
      case legacy_types.WebErrorStatus.WebErrorStatusOperationCanceled:
        return WebResourceErrorType.unknown;
      case legacy_types.WebErrorStatus.WebErrorStatusRedirectFailed:
        return WebResourceErrorType.redirectLoop;
      case legacy_types
          .WebErrorStatus
          .WebErrorStatusValidAuthenticationCredentialsRequired:
        return WebResourceErrorType.authentication;
      case legacy_types
          .WebErrorStatus
          .WebErrorStatusValidProxyAuthenticationRequired:
        return WebResourceErrorType.proxyAuthentication;
      case legacy_types
          .WebErrorStatus
          .WebErrorStatusCertificateCommonNameIsIncorrect:
      case legacy_types.WebErrorStatus.WebErrorStatusCertificateExpired:
      case legacy_types
          .WebErrorStatus
          .WebErrorStatusClientCertificateContainsErrors:
      case legacy_types.WebErrorStatus.WebErrorStatusCertificateRevoked:
      case legacy_types.WebErrorStatus.WebErrorStatusCertificateIsInvalid:
        return WebResourceErrorType.failedSslHandshake;
      case legacy_types
          .WebErrorStatus
          .WebErrorStatusErrorHTTPInvalidServerResponse:
      case legacy_types.WebErrorStatus.WebErrorStatusUnexpectedError:
      case legacy_types.WebErrorStatus.WebErrorStatusUnknown:
        return WebResourceErrorType.unknown;
    }
  }
}

class _WindowsWebViewPermissionRequest
    extends PlatformWebViewPermissionRequest {
  _WindowsWebViewPermissionRequest({required super.types});

  final Completer<legacy_types.WebviewPermissionDecision> decision =
      Completer<legacy_types.WebviewPermissionDecision>();

  @override
  Future<void> grant() async {
    if (!decision.isCompleted) {
      decision.complete(legacy_types.WebviewPermissionDecision.allow);
    }
  }

  @override
  Future<void> deny() async {
    if (!decision.isCompleted) {
      decision.complete(legacy_types.WebviewPermissionDecision.deny);
    }
  }
}
