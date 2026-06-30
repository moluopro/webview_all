/// Mode for an OHOS file chooser request.
enum FileChooserMode { open, openMultiple, save }

/// Console message severity reported by the OHOS Web component.
enum ConsoleMessageLevel { debug, error, log, tip, warning, unknown }

class WebResourceRequestData {
  WebResourceRequestData({
    required this.url,
    required this.isForMainFrame,
    this.isRedirect,
    required this.hasGesture,
    required this.method,
    required this.requestHeaders,
  });

  factory WebResourceRequestData.fromMessage(Object? value) {
    final Map<Object?, Object?> map = (value! as Map<Object?, Object?>);
    return WebResourceRequestData(
      url: map['url']! as String,
      isForMainFrame: map['isForMainFrame']! as bool,
      isRedirect: map['isRedirect'] as bool?,
      hasGesture: map['hasGesture']! as bool,
      method: map['method']! as String,
      requestHeaders: (map['requestHeaders']! as Map<Object?, Object?>)
          .cast<String, String>(),
    );
  }

  final String url;
  final bool isForMainFrame;
  final bool? isRedirect;
  final bool hasGesture;
  final String method;
  final Map<String, String> requestHeaders;
}

class WebResourceErrorData {
  WebResourceErrorData({required this.errorCode, required this.description});

  factory WebResourceErrorData.fromMessage(Object? value) {
    final Map<Object?, Object?> map = (value! as Map<Object?, Object?>);
    return WebResourceErrorData(
      errorCode: map['errorCode']! as int,
      description: map['description']! as String,
    );
  }

  final int errorCode;
  final String description;
}

class WebResourceResponseData {
  WebResourceResponseData({
    required this.statusCode,
    required this.responseHeaders,
    this.reasonPhrase,
    this.mimeType,
  });

  factory WebResourceResponseData.fromMessage(Object? value) {
    final Map<Object?, Object?> map = (value! as Map<Object?, Object?>);
    return WebResourceResponseData(
      statusCode: map['statusCode']! as int,
      responseHeaders: (map['responseHeaders']! as Map<Object?, Object?>)
          .cast<String, String>(),
      reasonPhrase: map['reasonPhrase'] as String?,
      mimeType: map['mimeType'] as String?,
    );
  }

  final int statusCode;
  final Map<String, String> responseHeaders;
  final String? reasonPhrase;
  final String? mimeType;
}

class WebViewPoint {
  WebViewPoint({required this.x, required this.y});

  final int x;
  final int y;
}

class ConsoleMessage {
  ConsoleMessage({
    required this.lineNumber,
    required this.message,
    required this.level,
    required this.sourceId,
  });

  factory ConsoleMessage.fromMessage(Object? value) {
    final Map<Object?, Object?> map = (value! as Map<Object?, Object?>);
    return ConsoleMessage(
      lineNumber: map['lineNumber']! as int,
      message: map['message']! as String,
      level: ConsoleMessageLevel.values[map['level']! as int],
      sourceId: map['sourceId']! as String,
    );
  }

  final int lineNumber;
  final String message;
  final ConsoleMessageLevel level;
  final String sourceId;
}
