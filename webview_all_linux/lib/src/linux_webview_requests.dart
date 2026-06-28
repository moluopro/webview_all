import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class LinuxPlatformWebViewPermissionRequest
    extends PlatformWebViewPermissionRequest {
  LinuxPlatformWebViewPermissionRequest({
    required super.types,
    required Future<void> Function() onGrant,
    required Future<void> Function() onDeny,
  }) : _onGrant = onGrant,
       _onDeny = onDeny;

  final Future<void> Function() _onGrant;
  final Future<void> Function() _onDeny;

  @override
  Future<void> grant() => _onGrant();

  @override
  Future<void> deny() => _onDeny();
}

class LinuxPlatformSslAuthError extends PlatformSslAuthError {
  LinuxPlatformSslAuthError({
    required String description,
    required Future<void> Function() onProceed,
    required Future<void> Function() onCancel,
  }) : _onProceed = onProceed,
       _onCancel = onCancel,
       super(certificate: const X509Certificate(), description: description);

  final Future<void> Function() _onProceed;
  final Future<void> Function() _onCancel;

  @override
  Future<void> proceed() => _onProceed();

  @override
  Future<void> cancel() => _onCancel();
}

class LinuxWebResourceError extends WebResourceError {
  LinuxWebResourceError({
    required super.errorCode,
    required super.description,
    required super.errorType,
    super.isForMainFrame,
    super.url,
  });

  factory LinuxWebResourceError.fromMap(Map<dynamic, dynamic> map) {
    return LinuxWebResourceError(
      errorCode: (map['errorCode'] as num?)?.toInt() ?? -1,
      description: '${map['description'] ?? 'Navigation failed'}',
      errorType: _mapErrorType((map['errorType'] as String?) ?? 'unknown'),
      isForMainFrame: map['isForMainFrame'] != false,
      url: map['url'] as String?,
    );
  }

  static WebResourceErrorType _mapErrorType(String type) {
    switch (type) {
      case 'authentication':
        return WebResourceErrorType.authentication;
      case 'badUrl':
        return WebResourceErrorType.badUrl;
      case 'connect':
        return WebResourceErrorType.connect;
      case 'failedSslHandshake':
        return WebResourceErrorType.failedSslHandshake;
      case 'file':
        return WebResourceErrorType.file;
      case 'fileNotFound':
        return WebResourceErrorType.fileNotFound;
      case 'hostLookup':
        return WebResourceErrorType.hostLookup;
      case 'io':
        return WebResourceErrorType.io;
      case 'proxyAuthentication':
        return WebResourceErrorType.proxyAuthentication;
      case 'redirectLoop':
        return WebResourceErrorType.redirectLoop;
      case 'timeout':
        return WebResourceErrorType.timeout;
      case 'tooManyRequests':
        return WebResourceErrorType.tooManyRequests;
      case 'unsafeResource':
        return WebResourceErrorType.unsafeResource;
      case 'unsupportedScheme':
        return WebResourceErrorType.unsupportedScheme;
      case 'webContentProcessTerminated':
        return WebResourceErrorType.webContentProcessTerminated;
      case 'webViewInvalidated':
        return WebResourceErrorType.webViewInvalidated;
      default:
        return WebResourceErrorType.unknown;
    }
  }
}
