## 1.1.1

* Update the example app to use `abutil` for platform detection.
* Simplify the example app's OHOS and Web platform branches.
* Synchronize platform package license files with the main package license.

## 1.1.0

* Add OpenHarmony platform implementation support.
* Improve cookie API coverage:
  * Add the common `WebViewCookieManager.getCookies(Uri)` API to the main plugin wrapper.
  * Implement and validate cross-platform cookie reads for the federated platform packages.
  * Add Windows WebView2-specific cookie APIs for full cookie metadata and deletion workflows.
* Harden the Web platform implementation:
  * Preserve logical `currentUrl()` values for `loadHtmlString` and XHR-backed `loadRequest` calls instead of exposing internal `data:` iframe URLs.
  * Resolve Flutter web assets through the generated `assets/` directory and encode asset path segments correctly.
  * Report XHR-backed load failures through `onWebResourceError` and keep unsupported user agent overrides from being reported as applied.
  * Validate and encode browser-visible cookies before writing to `document.cookie`, and document iframe and browser cookie limitations.
* Improve the Linux platform implementation:
  * Fix native WebView visibility synchronization so a stable Flutter frame no longer collapses the GTK/WebKit view to `0x0`.
  * Harden Linux frame, cookie, and JavaScript channel inputs to avoid invalid native state and unsafe script injection.
* Keep federated platform package changelogs aligned with the main `webview_all` updates.
* Synchronize the main plugin and federated platform package versions.

## 1.0.3

* doc update
* dep update

## 1.0.2

* doc update

## 1.0.1

* doc update

## 1.0.0

* add linux support

## 0.9.3

* bug fix

## 0.9.2

* bug fix

## 0.9.1

* refactor: breaking changes

## 0.5.3

* update dependences
    * fix the error opaque is not implemented on MacOs

## 0.5.2

* doc update  

## 0.5.1

* big dep update  
* bug fix

## 0.4.5

* dep update  
* bug fix

## 0.4.3

* dep update

## 0.4.1

* refactor

## 0.3.7

* dep update

## 0.3.6

* doc update

## 0.3.5

* doc update

## 0.3.4

* doc update

## 0.3.3

* doc update

## 0.3.1

* fix bugs about web

## 0.2.4

* dep update

## 0.2.3

* doc update

## 0.2.2

* fix bugs about web

## 0.2.1

* run successfully

## 0.1.3

* fix bugs

## 0.1.2

* fix bugs

## 0.1.1

* Our story begins
