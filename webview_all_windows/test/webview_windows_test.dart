import 'package:flutter_test/flutter_test.dart';
import 'package:webview_all_windows/webview_all_windows.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  test('registerWith sets the Windows WebView platform implementation', () {
    final WebViewPlatform? previousInstance = WebViewPlatform.instance;
    addTearDown(() {
      if (previousInstance != null) {
        WebViewPlatform.instance = previousInstance;
      }
    });

    WindowsWebViewPlatform.registerWith();

    expect(WebViewPlatform.instance, isA<WindowsWebViewPlatform>());
  });
}
