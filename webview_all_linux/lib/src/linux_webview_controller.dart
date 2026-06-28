import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'linux_navigation_delegate.dart';
import 'linux_webview_constants.dart';
import 'linux_webview_creation_params.dart';
import 'linux_webview_requests.dart';

part 'linux_webview_events.dart';

class LinuxWebViewController extends PlatformWebViewController {
  LinuxWebViewController(PlatformWebViewControllerCreationParams params)
    : super.implementation(
        params is LinuxWebViewControllerCreationParams
            ? params
            : LinuxWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                params,
              ),
      ) {
    _readyFuture = _initialize();
  }

  static const MethodChannel rootChannel = MethodChannel(
    linuxWebViewChannelPrefix,
  );
  static final RegExp _javaScriptIdentifierPattern = RegExp(
    r'^[A-Za-z_$][A-Za-z0-9_$]*$',
  );

  Future<void>? _readyFuture;
  MethodChannel? _channel;
  EventChannel? _eventChannel;
  StreamSubscription<dynamic>? _eventSubscription;

  LinuxNavigationDelegate? _navigationDelegate;
  final Map<String, JavaScriptChannelParams> _javaScriptChannels =
      <String, JavaScriptChannelParams>{};

  String? _currentUrl;
  String? _title;
  String? _userAgent;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _disposed = false;

  void Function(JavaScriptConsoleMessage consoleMessage)? _onConsoleMessage;
  void Function(ScrollPositionChange scrollPositionChange)?
  _onScrollPositionChange;
  void Function(PlatformWebViewPermissionRequest request)? _onPermissionRequest;
  Future<void> Function(JavaScriptAlertDialogRequest request)?
  _onJavaScriptAlertDialog;
  Future<bool> Function(JavaScriptConfirmDialogRequest request)?
  _onJavaScriptConfirmDialog;
  Future<String> Function(JavaScriptTextInputDialogRequest request)?
  _onJavaScriptTextInputDialog;

  Future<void> _initialize() async {
    final int id =
        await rootChannel.invokeMethod<int>('createWebView') ??
        (throw StateError('Failed to create Linux WebView instance.'));
    _channel = MethodChannel('$linuxWebViewChannelPrefix/$id');
    _eventChannel = EventChannel('$linuxWebViewChannelPrefix/$id/events');
    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (_) {},
    );
  }

  Future<void> _ensureReady() async {
    await _readyFuture;
    if (_disposed) {
      throw StateError(
        'This LinuxWebViewController has already been disposed.',
      );
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    await _ensureReady();
    return _channel!.invokeMethod<T>(method, arguments);
  }

  @override
  Future<void> loadFile(String absoluteFilePath) async {
    final File file = File(absoluteFilePath);
    if (!file.existsSync()) {
      throw ArgumentError.value(
        absoluteFilePath,
        'absoluteFilePath',
        'File does not exist.',
      );
    }

    await _invoke<void>('loadFile', <String, Object?>{
      'path': file.absolute.path,
    });
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    final String assetPath = _resolveFlutterAssetPath(key);
    final File file = File(assetPath);
    if (!file.existsSync()) {
      throw ArgumentError.value(key, 'key', 'Asset for key "$key" not found.');
    }

    await loadFile(assetPath);
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    return _invoke<void>('loadHtmlString', <String, Object?>{
      'html': html,
      'baseUrl': baseUrl,
    });
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    if (!params.uri.hasScheme) {
      throw ArgumentError(
        'LoadRequestParams#uri is required to have a scheme.',
      );
    }

    if (params.method != LoadRequestMethod.get ||
        (params.body != null && params.body!.isNotEmpty)) {
      throw UnsupportedError(
        'WebKitGTK navigation requests support URLs and custom headers here, '
        'but do not expose a stable API for arbitrary HTTP methods or bodies.',
      );
    }

    await _invoke<void>('loadRequest', <String, Object?>{
      'url': params.uri.toString(),
      'headers': params.headers,
    });
  }

  @override
  Future<String?> currentUrl() async {
    await _ensureReady();
    return _currentUrl ?? await _channel!.invokeMethod<String>('currentUrl');
  }

  @override
  Future<bool> canGoBack() async {
    await _ensureReady();
    return (await _channel!.invokeMethod<bool>('canGoBack')) ?? _canGoBack;
  }

  @override
  Future<bool> canGoForward() async {
    await _ensureReady();
    return (await _channel!.invokeMethod<bool>('canGoForward')) ??
        _canGoForward;
  }

  @override
  Future<void> goBack() => _invoke<void>('goBack');

  @override
  Future<void> goForward() => _invoke<void>('goForward');

  @override
  Future<void> reload() => _invoke<void>('reload');

  @override
  Future<void> clearCache() => _invoke<void>('clearCache');

  @override
  Future<void> clearLocalStorage() => _invoke<void>('clearLocalStorage');

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    _navigationDelegate = handler as LinuxNavigationDelegate;
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return _invoke<void>('runJavaScript', <String, Object?>{
      'script': javaScript,
    });
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    final Object? result = await _invoke<Object>(
      'runJavaScriptReturningResult',
      <String, Object?>{'script': javaScript},
    );

    if (result == null) {
      throw ArgumentError(
        'The JavaScript returned `null` or `undefined`, which is unsupported.',
      );
    }

    if (result case final Map<Object?, Object?> map
        when map['__json__'] is String) {
      final Object? decoded = jsonDecode(map['__json__']! as String);
      if (decoded == null) {
        throw ArgumentError(
          'The JavaScript returned `null` or `undefined`, which is unsupported.',
        );
      }
      return decoded;
    }

    return result;
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    final String name = javaScriptChannelParams.name;
    if (!_javaScriptIdentifierPattern.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'javaScriptChannelParams.name',
        'JavaScript channel names must be valid JavaScript identifiers.',
      );
    }

    if (_javaScriptChannels.containsKey(name)) {
      throw ArgumentError(
        'A JavaScriptChannel with name `$name` already exists.',
      );
    }

    _javaScriptChannels[name] = javaScriptChannelParams;
    await _invoke<void>('addJavaScriptChannel', <String, Object?>{
      'name': name,
    });
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    _javaScriptChannels.remove(javaScriptChannelName);
    await _invoke<void>('removeJavaScriptChannel', <String, Object?>{
      'name': javaScriptChannelName,
    });
  }

  @override
  Future<String?> getTitle() async {
    await _ensureReady();
    return _title ?? await _channel!.invokeMethod<String>('getTitle');
  }

  @override
  Future<void> scrollTo(int x, int y) {
    return _invoke<void>('scrollTo', <String, Object?>{'x': x, 'y': y});
  }

  @override
  Future<void> scrollBy(int x, int y) {
    return _invoke<void>('scrollBy', <String, Object?>{'x': x, 'y': y});
  }

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) {
    return _invoke<void>('setVerticalScrollBarEnabled', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) {
    return _invoke<void>('setHorizontalScrollBarEnabled', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  bool supportsSetScrollBarsEnabled() => true;

  @override
  Future<Offset> getScrollPosition() async {
    final Map<Object?, Object?>? offset = await _invoke<Map<Object?, Object?>>(
      'getScrollPosition',
    );
    return Offset(
      (offset?['x'] as num?)?.toDouble() ?? 0,
      (offset?['y'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<void> enableZoom(bool enabled) {
    return _invoke<void>('enableZoom', <String, Object?>{'enabled': enabled});
  }

  @override
  Future<void> setBackgroundColor(Color color) {
    return _invoke<void>('setBackgroundColor', <String, Object?>{
      'r': color.r,
      'g': color.g,
      'b': color.b,
      'a': color.a,
    });
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) {
    return _invoke<void>('setJavaScriptMode', <String, Object?>{
      'enabled': javaScriptMode == JavaScriptMode.unrestricted,
    });
  }

  @override
  Future<void> setUserAgent(String? userAgent) async {
    _userAgent = userAgent;
    await _invoke<void>('setUserAgent', <String, Object?>{
      'userAgent': userAgent,
    });
  }

  @override
  Future<String?> getUserAgent() async {
    await _ensureReady();
    return _userAgent ?? await _channel!.invokeMethod<String>('getUserAgent');
  }

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    _onPermissionRequest = onPermissionRequest;
  }

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {
    _onConsoleMessage = onConsoleMessage;
    await _invoke<void>('setOnConsoleMessage', <String, Object?>{
      'enabled': true,
    });
  }

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)?
    onScrollPositionChange,
  ) async {
    _onScrollPositionChange = onScrollPositionChange;
    await _invoke<void>('setOnScrollPositionChange', <String, Object?>{
      'enabled': onScrollPositionChange != null,
    });
  }

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request)
    onJavaScriptAlertDialog,
  ) async {
    _onJavaScriptAlertDialog = onJavaScriptAlertDialog;
  }

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request)
    onJavaScriptConfirmDialog,
  ) async {
    _onJavaScriptConfirmDialog = onJavaScriptConfirmDialog;
  }

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request)
    onJavaScriptTextInputDialog,
  ) async {
    _onJavaScriptTextInputDialog = onJavaScriptTextInputDialog;
  }

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) async {
    if (mode == WebViewOverScrollMode.never) {
      await runJavaScript('''
        document.documentElement.style.overscrollBehavior = 'none';
        document.body.style.overscrollBehavior = 'none';
      ''');
    }
  }

  Future<void> setFrame(Rect rect, {required bool visible}) {
    return _invoke<void>('setFrame', <String, Object?>{
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'visible': visible,
    });
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _eventSubscription?.cancel();
    if (_channel != null) {
      try {
        await _channel!.invokeMethod<void>('dispose');
      } catch (_) {
        // Best effort during shutdown.
      }
    }
  }

  String _resolveFlutterAssetPath(String key) {
    return path.joinAll(<String>[
      path.dirname(Platform.resolvedExecutable),
      'data',
      'flutter_assets',
      ...key.split('/'),
    ]);
  }
}
