# webview_all_web

This is the web implementation of the [`webview_all`](https://pub.dev/packages/webview_all) plugin.

It is currently severely limited and doesn't implement most of the available functionality.
The following functionality is currently available:

- `loadRequest`
- `loadHtmlString` (Without `baseUrl`)

Nothing else is currently supported.

## Usage

This package is the federated web implementation used by `webview_all`.
Applications should normally depend on `webview_all` directly; Flutter will
resolve this package automatically for the web platform.
