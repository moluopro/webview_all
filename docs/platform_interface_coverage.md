# Platform Interface Coverage

This document tracks how `webview_all` maps the public
`webview_flutter_platform_interface` API across its federated platform
packages.

## Baseline

Current baseline:

* `webview_flutter`: `4.14.0`
* `webview_flutter_platform_interface`: `2.15.1`

The main `webview_all` wrapper should keep the same public API shape as
`webview_flutter` wherever an equivalent API exists. Platform packages should
extend the corresponding `PlatformWebViewController`,
`PlatformNavigationDelegate`, `PlatformWebViewWidget`, and
`PlatformWebViewCookieManager` classes.

## Coverage Summary

| Area | Linux | OHOS | Web | Windows |
| --- | --- | --- | --- | --- |
| `WebViewPlatform` factory methods | Covered | Covered | Covered | Covered |
| `PlatformWebViewWidget.build` | Covered | Covered | Covered | Covered |
| Cookie manager `clearCookies` | Covered | Covered | Covered | Covered |
| Cookie manager `setCookie` | Covered | Covered | Covered | Covered |
| Cookie manager `getCookies` | Covered | Covered | Covered | Covered |
| Navigation delegate core callbacks | Covered | Covered | Covered | Covered |
| HTTP status error callback | Covered | Registration covered; native event pending | Covered | Covered |
| HTTP auth callback | Covered | Covered | Registration covered; browser event unavailable | Registration covered |
| SSL auth callback | Covered | Registration covered; native event pending | Registration covered; browser event unavailable | Registration covered |
| Controller load/navigation/history APIs | Covered | Covered | Covered with browser limits | Covered |
| JavaScript execution | Covered | Covered | Unsupported by browser iframe model | Covered |
| JavaScript channels | Covered | Covered | Unsupported by browser iframe model | Covered |
| JavaScript dialog callbacks | Registration covered | Covered | Unsupported by browser iframe model | Unsupported |
| Permission request callback | Registration covered | Covered | Unsupported by browser iframe model | Covered |
| Scroll position APIs | Covered | Covered | Limited to iframe state | Covered |
| Scrollbar visibility toggles | Covered | Unsupported | Unsupported | Unsupported |
| Background color | Covered | Covered | Limited to iframe element | Covered |
| User agent override | Covered | Covered | Unsupported by browser iframe model | Covered, reset unsupported |
| Over-scroll mode | Covered | Registration covered; native behavior pending | Unsupported/no-op | Partially covered |

## Maintenance Rules

When upgrading `webview_flutter_platform_interface`:

1. Compare these upstream files against each platform package:
   * `platform_webview_controller.dart`
   * `platform_navigation_delegate.dart`
   * `platform_webview_widget.dart`
   * `platform_webview_cookie_manager.dart`
   * `webview_platform.dart`
2. Add explicit overrides for every new common method in every federated
   platform package.
3. Prefer a real native implementation when the engine exposes one.
4. Use `UnsupportedError` when an API cannot be provided and user code should
   not assume success.
5. Use a no-op only for capability registration or APIs guarded by an explicit
   support check, such as `supportsSetScrollBarsEnabled`.
6. Document platform limits in `webview_all/README.md` and
   `webview_all/README-ZH.md`.
7. Verify with the available test environments:
   * macOS locally with the normal Flutter SDK.
   * OHOS real device with the OHOS Flutter SDK.
   * Ubuntu 24.04 over SSH for Linux.
   * Windows 11 over SSH for Windows.

## Known Follow-Up Work

* Bridge OHOS HTTP status errors if ArkWeb exposes an equivalent callback.
* Bridge OHOS recoverable SSL auth errors if ArkWeb exposes an equivalent
  callback.
* Investigate Windows JavaScript dialog callback support through WebView2.
* Investigate Windows scrollbar visibility support or document a permanent
  unsupported status if WebView2 does not expose a stable API.
* Keep Web platform behavior strict around browser security restrictions.
