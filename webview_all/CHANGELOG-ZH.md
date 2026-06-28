## 1.1.2

* 将 `WebViewCookieManager.getCookies({required Uri domain})` 与上游 `webview_flutter` 公共 API 对齐。

## 1.1.1

* 示例改为使用 `abutil` 包进行平台判断。
* 简化示例应用中的 OHOS 与 Web 平台分支。
* 将平台包的许可证文件同步为主包许可证文本。

## 1.1.0

* 新增 OpenHarmony 平台实现支持。
* 完善 cookie API 覆盖：
  * 在主插件封装层新增通用 `WebViewCookieManager.getCookies({required Uri domain})` API。
  * 为各 federated 平台包实现并验证跨平台 cookie 读取能力。
  * 为 Windows WebView2 增加包含完整 cookie 元数据与删除流程的平台专用 API。
* 加强 Web 平台实现：
  * 为 `loadHtmlString` 与基于 XHR 的 `loadRequest` 保留逻辑 `currentUrl()`，避免向用户暴露内部 `data:` iframe URL。
  * 按 Flutter Web 生成的 `assets/` 目录解析资源，并正确编码资源路径片段。
  * 基于 XHR 的加载失败会通过 `onWebResourceError` 上报，且不再把不支持的自定义 user agent 覆盖误报为已生效。
  * 写入 `document.cookie` 前校验并编码浏览器可见 cookie，在文档中明确 iframe 与浏览器 cookie 限制。
* 完善 Linux 平台实现：
  * 修复 native WebView 可见性同步问题，稳定的 Flutter 帧不再把 GTK/WebKit 视图折叠为 `0x0`。
  * 加强 Linux frame、cookie 与 JavaScript channel 的入参校验，避免非法 native 状态和不安全脚本注入。
* 各平台子插件的更新日志统一为 `webview_all` 的更新内容。
* 统一主插件与各平台子插件的版本号。

## 1.0.3

* 文档更新。
* 依赖更新。

## 1.0.2

* 文档更新。

## 1.0.1

* 文档更新。

## 1.0.0

* 新增 Linux 支持。

## 0.9.3

* 问题修复。

## 0.9.2

* 问题修复。

## 0.9.1

* 重构：包含破坏性变更。

## 0.5.3

* 更新依赖。
  * 修复 MacOS 上 `opaque` 未实现导致的问题。

## 0.5.2

* 文档更新。

## 0.5.1

* 大版本依赖更新。
* 问题修复。

## 0.4.5

* 依赖更新。
* 问题修复。

## 0.4.3

* 依赖更新。

## 0.4.1

* 重构。

## 0.3.7

* 依赖更新。

## 0.3.6

* 文档更新。

## 0.3.5

* 文档更新。

## 0.3.4

* 文档更新。

## 0.3.3

* 文档更新。

## 0.3.1

* 修复 Web 相关问题。

## 0.2.4

* 依赖更新。

## 0.2.3

* 文档更新。

## 0.2.2

* 修复 Web 相关问题。

## 0.2.1

* 初步运行成功。

## 0.1.3

* 问题修复。

## 0.1.2

* 问题修复。

## 0.1.1

* 故事开始。
