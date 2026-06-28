part of 'linux_webview_controller.dart';

extension LinuxWebViewControllerEventHandling on LinuxWebViewController {
  void _handleEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final String? type = event['type'] as String?;
    switch (type) {
      case 'urlChanged':
        final String url = '${event['url'] ?? ''}';
        _currentUrl = url;
        _navigationDelegate?.handleUrlChange(url);
        break;
      case 'pageStarted':
        final String url = '${event['url'] ?? ''}';
        _currentUrl = url;
        _navigationDelegate?.handlePageStarted(url);
        break;
      case 'pageFinished':
        final String url = '${event['url'] ?? ''}';
        _currentUrl = url;
        _navigationDelegate?.handlePageFinished(url);
        break;
      case 'progress':
        _navigationDelegate?.handleProgress(
          (event['progress'] as num?)?.round() ?? 0,
        );
        break;
      case 'historyChanged':
        _canGoBack = event['canGoBack'] == true;
        _canGoForward = event['canGoForward'] == true;
        break;
      case 'titleChanged':
        _title = event['title'] as String?;
        break;
      case 'webResourceError':
        _navigationDelegate?.handleWebResourceError(
          LinuxWebResourceError.fromMap(event),
        );
        break;
      case 'httpError':
        if (_navigationDelegate != null) {
          _navigationDelegate!.handleHttpError(
            HttpResponseError(
              response: WebResourceResponse(
                uri: Uri.tryParse('${event['url'] ?? ''}'),
                statusCode: (event['statusCode'] as num?)?.toInt() ?? 0,
              ),
            ),
          );
        }
        break;
      case 'javaScriptChannelMessage':
        final String name = '${event['channelName'] ?? ''}';
        final JavaScriptChannelParams? params = _javaScriptChannels[name];
        if (params != null) {
          params.onMessageReceived(
            JavaScriptMessage(message: '${event['message'] ?? ''}'),
          );
        }
        break;
      case 'consoleMessage':
        final callback = _onConsoleMessage;
        if (callback != null) {
          callback(
            JavaScriptConsoleMessage(
              level: _parseJavaScriptLogLevel(event['level'] as String?),
              message: '${event['message'] ?? ''}',
            ),
          );
        }
        break;
      case 'scrollPositionChange':
        final callback = _onScrollPositionChange;
        if (callback != null) {
          callback(
            ScrollPositionChange(
              (event['x'] as num?)?.toDouble() ?? 0,
              (event['y'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
        break;
      case 'navigationRequest':
        _handleNavigationRequestEvent(event);
        break;
      case 'httpAuthRequest':
        unawaited(_handleHttpAuthRequestEvent(event));
        break;
      case 'sslAuthError':
        unawaited(_handleSslAuthErrorEvent(event));
        break;
      case 'permissionRequest':
        unawaited(_handlePermissionRequestEvent(event));
        break;
      case 'javaScriptDialog':
        unawaited(_handleJavaScriptDialogEvent(event));
        break;
    }
  }

  Future<void> _handleNavigationRequestEvent(
    Map<dynamic, dynamic> event,
  ) async {
    final int requestId = (event['requestId'] as num?)?.toInt() ?? -1;
    bool allow = true;
    if (_navigationDelegate?.hasNavigationRequestHandler ?? false) {
      final NavigationDecision? decision = await _navigationDelegate!
          .decideNavigation(
            NavigationRequest(
              url: '${event['url'] ?? ''}',
              isMainFrame: event['isMainFrame'] != false,
            ),
          );
      allow = decision == NavigationDecision.navigate;
    }

    await _invoke<void>('completeNavigationRequest', <String, Object?>{
      'requestId': requestId,
      'allow': allow,
    });
  }

  Future<void> _handleHttpAuthRequestEvent(Map<dynamic, dynamic> event) async {
    final int requestId = (event['requestId'] as num?)?.toInt() ?? -1;
    if (!(_navigationDelegate?.hasHttpAuthRequestHandler ?? false)) {
      await _invoke<void>('completeHttpAuthRequest', <String, Object?>{
        'requestId': requestId,
        'action': 'cancel',
      });
      return;
    }

    _navigationDelegate!.handleHttpAuthRequest(
      HttpAuthRequest(
        host: '${event['host'] ?? ''}',
        realm: event['realm'] as String?,
        onProceed: (WebViewCredential credential) {
          unawaited(
            _invoke<void>('completeHttpAuthRequest', <String, Object?>{
              'requestId': requestId,
              'action': 'proceed',
              'user': credential.user,
              'password': credential.password,
            }),
          );
        },
        onCancel: () {
          unawaited(
            _invoke<void>('completeHttpAuthRequest', <String, Object?>{
              'requestId': requestId,
              'action': 'cancel',
            }),
          );
        },
      ),
    );
  }

  Future<void> _handleSslAuthErrorEvent(Map<dynamic, dynamic> event) async {
    final int requestId = (event['requestId'] as num?)?.toInt() ?? -1;
    if (!(_navigationDelegate?.hasSslAuthErrorHandler ?? false)) {
      await _invoke<void>('completeSslAuthError', <String, Object?>{
        'requestId': requestId,
        'proceed': false,
      });
      return;
    }

    _navigationDelegate!.handleSslAuthError(
      LinuxPlatformSslAuthError(
        description: '${event['description'] ?? 'TLS certificate error'}',
        onProceed: () {
          return _invoke<void>('completeSslAuthError', <String, Object?>{
            'requestId': requestId,
            'proceed': true,
          });
        },
        onCancel: () {
          return _invoke<void>('completeSslAuthError', <String, Object?>{
            'requestId': requestId,
            'proceed': false,
          });
        },
      ),
    );
  }

  Future<void> _handlePermissionRequestEvent(
    Map<dynamic, dynamic> event,
  ) async {
    final int requestId = (event['requestId'] as num?)?.toInt() ?? -1;
    final callback = _onPermissionRequest;
    if (callback == null) {
      await _invoke<void>('completePermissionRequest', <String, Object?>{
        'requestId': requestId,
        'grant': false,
      });
      return;
    }

    final List<Object?> rawTypes =
        (event['types'] as List<Object?>?) ?? const <Object?>[];
    callback(
      LinuxPlatformWebViewPermissionRequest(
        types: rawTypes
            .map((Object? type) => _parsePermissionType(type as String?))
            .whereType<WebViewPermissionResourceType>()
            .toSet(),
        onGrant: () {
          return _invoke<void>('completePermissionRequest', <String, Object?>{
            'requestId': requestId,
            'grant': true,
          });
        },
        onDeny: () {
          return _invoke<void>('completePermissionRequest', <String, Object?>{
            'requestId': requestId,
            'grant': false,
          });
        },
      ),
    );
  }

  Future<void> _handleJavaScriptDialogEvent(Map<dynamic, dynamic> event) async {
    final int requestId = (event['requestId'] as num?)?.toInt() ?? -1;
    final String dialogType = '${event['dialogType'] ?? ''}';
    final String message = '${event['message'] ?? ''}';
    final String url = '${event['url'] ?? ''}';
    try {
      switch (dialogType) {
        case 'alert':
          final callback = _onJavaScriptAlertDialog;
          if (callback == null) {
            await _completeJavaScriptDialog(requestId, action: 'confirm');
            return;
          }
          await callback(
            JavaScriptAlertDialogRequest(message: message, url: url),
          );
          await _completeJavaScriptDialog(requestId, action: 'confirm');
          return;
        case 'confirm':
        case 'beforeUnloadConfirm':
          final callback = _onJavaScriptConfirmDialog;
          if (callback == null) {
            await _completeJavaScriptDialog(requestId, action: 'confirm');
            return;
          }
          final bool confirmed = await callback(
            JavaScriptConfirmDialogRequest(message: message, url: url),
          );
          await _completeJavaScriptDialog(
            requestId,
            action: confirmed ? 'confirm' : 'cancel',
          );
          return;
        case 'prompt':
          final callback = _onJavaScriptTextInputDialog;
          if (callback == null) {
            await _completeJavaScriptDialog(
              requestId,
              action: 'confirm',
              text: (event['defaultText'] as String?) ?? '',
            );
            return;
          }
          final String text = await callback(
            JavaScriptTextInputDialogRequest(
              message: message,
              url: url,
              defaultText: event['defaultText'] as String?,
            ),
          );
          await _completeJavaScriptDialog(
            requestId,
            action: 'confirm',
            text: text,
          );
          return;
      }
    } catch (_) {
      await _completeJavaScriptDialog(requestId, action: 'cancel');
      return;
    }

    await _completeJavaScriptDialog(requestId, action: 'confirm');
  }

  Future<void> _completeJavaScriptDialog(
    int requestId, {
    required String action,
    String? text,
  }) {
    return _invoke<void>('completeJavaScriptDialog', <String, Object?>{
      'requestId': requestId,
      'action': action,
      'text': text,
    });
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

  WebViewPermissionResourceType? _parsePermissionType(String? type) {
    switch (type) {
      case 'camera':
        return WebViewPermissionResourceType.camera;
      case 'microphone':
        return WebViewPermissionResourceType.microphone;
    }
    return null;
  }
}
