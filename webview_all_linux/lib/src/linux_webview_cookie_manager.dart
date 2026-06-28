import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'linux_webview_controller.dart';

class LinuxWebViewCookieManagerCreationParams
    extends PlatformWebViewCookieManagerCreationParams {
  const LinuxWebViewCookieManagerCreationParams();

  const LinuxWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
    PlatformWebViewCookieManagerCreationParams params,
  );
}

class LinuxWebViewCookieManager extends PlatformWebViewCookieManager {
  LinuxWebViewCookieManager(PlatformWebViewCookieManagerCreationParams params)
    : super.implementation(
        params is LinuxWebViewCookieManagerCreationParams
            ? params
            : LinuxWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
                params,
              ),
      );

  @override
  Future<bool> clearCookies() async {
    final bool? value = await LinuxWebViewController.rootChannel.invokeMethod(
      'clearCookies',
    );
    return value ?? false;
  }

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    return LinuxWebViewController.rootChannel.invokeMethod<void>('setCookie', {
      'name': cookie.name,
      'value': cookie.value,
      'domain': cookie.domain,
      'path': cookie.path,
    });
  }

  @override
  Future<List<WebViewCookie>> getCookies(Uri url) async {
    final List<Object?> rawCookies =
        await LinuxWebViewController.rootChannel.invokeListMethod<Object?>(
          'getCookies',
          <String, Object?>{'url': url.toString()},
        ) ??
        const <Object?>[];

    return rawCookies.whereType<Map<Object?, Object?>>().map((cookie) {
      return WebViewCookie(
        name: '${cookie['name'] ?? ''}',
        value: '${cookie['value'] ?? ''}',
        domain: '${cookie['domain'] ?? url.host}',
        path: '${cookie['path'] ?? '/'}',
      );
    }).toList();
  }
}
