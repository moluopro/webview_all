import 'package:flutter_test/flutter_test.dart';
import 'package:webview_all_ohos/src/core/instance_manager.dart';
import 'package:webview_all_ohos/src/ohos_webview_native.dart';
import 'package:webview_all_ohos/webview_all_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// ignore: must_be_immutable
class TestCookieManager extends CookieManager {
  TestCookieManager()
      : super.detached(
          instanceManager: InstanceManager(onWeakReferenceRemoved: (_) {}),
        );

  String cookies = '';
  String? lastGetCookiesUrl;
  String? lastSetCookieUrl;
  String? lastSetCookieValue;

  @override
  Future<String> getCookies(String url) async {
    lastGetCookiesUrl = url;
    return cookies;
  }

  @override
  Future<void> setCookie(String url, String value) async {
    lastSetCookieUrl = url;
    lastSetCookieValue = value;
  }
}

void main() {
  test('registerWith sets the OHOS WebView platform implementation', () {
    final WebViewPlatform? previousInstance = WebViewPlatform.instance;
    addTearDown(() {
      if (previousInstance != null) {
        WebViewPlatform.instance = previousInstance;
      }
    });

    OhosWebViewPlatform.registerWith();

    expect(WebViewPlatform.instance, isA<OhosWebViewPlatform>());
  });

  test('cookie manager encodes cookies before setting them', () async {
    final TestCookieManager testCookieManager = TestCookieManager();
    final OhosWebViewCookieManager cookieManager = OhosWebViewCookieManager(
      const PlatformWebViewCookieManagerCreationParams(),
      cookieManager: testCookieManager,
    );

    await cookieManager.setCookie(
      const WebViewCookie(
        name: 'session id',
        value: 'abc=123',
        domain: 'https://example.com',
      ),
    );

    expect(testCookieManager.lastSetCookieUrl, 'https://example.com');
    expect(
      testCookieManager.lastSetCookieValue,
      'session%20id=abc%3D123; path=/',
    );
  });

  test('cookie manager parses fetched cookies', () async {
    final TestCookieManager testCookieManager = TestCookieManager()
      ..cookies = 'session=abc123; token=a=b; malformed';
    final OhosWebViewCookieManager cookieManager = OhosWebViewCookieManager(
      const PlatformWebViewCookieManagerCreationParams(),
      cookieManager: testCookieManager,
    );
    final Uri url = Uri.parse('https://example.com/path');

    final List<WebViewCookie> cookies = await cookieManager.getCookies(url);

    expect(testCookieManager.lastGetCookiesUrl, url.toString());
    expect(cookies, hasLength(2));
    expect(cookies[0].name, 'session');
    expect(cookies[0].value, 'abc123');
    expect(cookies[0].domain, url.host);
    expect(cookies[0].path, '/');
    expect(cookies[1].name, 'token');
    expect(cookies[1].value, 'a=b');
  });
}
