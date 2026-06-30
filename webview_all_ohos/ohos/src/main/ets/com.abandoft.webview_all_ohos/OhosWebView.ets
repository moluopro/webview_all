import web_webview from '@ohos.web.webview';
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { WebViewPlatformView } from './WebViewPlatformView';

@Observed
export declare class Params {
  direction: Direction;
  platformView: PlatformView;
}

@Component
export struct OhosWebView {
  @ObjectLink params: Params;

  webView: WebViewPlatformView = this.params.platformView as WebViewPlatformView;
  controller: web_webview.WebviewController = this.webView.getController();

  @State textZoomRatio: number = this.webView.getWebSettings().getTextZoom();
  @State disposed: boolean = false;

  aboutToAppear(): void {
    this.webView.getWebSettings().onTextZoomChanged((ratio: number) => {
      this.textZoomRatio = ratio;
    });
    this.webView.setOnDisposeCallback(() => {
      this.disposed = true;
    });
  }

  build() {
    Column() {
      if (!this.disposed) {
        Web({ src: this.webView.getUrl(), controller: this.controller })
          .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_VISUAL)
          .backgroundColor(this.webView.getWebSettings().getBackgroundColor())
          .domStorageAccess(this.webView.getWebSettings().getDomStorageEnabled())
          .allowWindowOpenMethod(this.webView.getWebSettings().getJavaScriptCanOpenWindowsAutomatically())
          .multiWindowAccess(false)
          .javaScriptAccess(this.webView.getWebSettings().getJavaScriptEnabled())
          .mediaPlayGestureAccess(this.webView.getWebSettings().getMediaPlaybackRequiresUserGesture())
          .zoomAccess(this.webView.getWebSettings().getSupportZoom())
          .overviewModeAccess(this.webView.getWebSettings().getLoadWithOverviewMode())
          .wideViewModeAccess(this.webView.getWebSettings().getUseWideViewPort())
          .metaViewport(this.webView.getWebSettings().getUseWideViewPort())
          .fileAccess(this.webView.getWebSettings().getAllowFileAccess())
          .textZoomRatio(this.textZoomRatio)
          .mixedMode(MixedMode.All)
          .onControllerAttached(this.webView.onControllerAttached)
          .onDownloadStart(this.webView.onDownloadStart)
          .onPageBegin(this.webView.onPageBegin)
          .onPageEnd(this.webView.onPageEnd)
          .onErrorReceive(this.webView.onErrorReceive)
          .onHttpErrorReceive(this.webView.onHttpErrorReceive)
          .onRefreshAccessedHistory(this.webView.onRefreshAccessedHistory)
          .onProgressChange(this.webView.onProgressChange)
          .onGeolocationShow(this.webView.onGeolocationShow)
          .onGeolocationHide(this.webView.onGeolocationHide)
          .onShowFileSelector(this.webView.onShowFileSelector)
          .onPermissionRequest(this.webView.onPermissionRequest)
          .onConsole(this.webView.onConsoleMessage)
          .onWindowExit(this.webView.onWindowExit)
          .onWindowNew(this.webView.onWindowNew)
          .onSslErrorEventReceive(this.webView.onSslErrorEventReceive)
          .onHttpAuthRequest(this.webView.onHttpAuthRequest)
          .onAlert(this.webView.onJsAlert)
          .onConfirm(this.webView.onJsConfirm)
          .onPrompt(this.webView.onJsPrompt)
          .onOverrideUrlLoading(this.webView.onOverrideUrlLoading)
          .onFullScreenEnter(this.webView.onFullScreenEnter)
          .onFullScreenExit(this.webView.onFullScreenExit)
          .onScroll(this.webView.onScroll)
      }
    }
  }
}

@Builder
export function WebBuilder(params: Params) {
  OhosWebView({
    params: params,
    webView: params.platformView as WebViewPlatformView,
    controller: (params.platformView as WebViewPlatformView).getController()
  }).backgroundColor(Color.Transparent)
}

@CustomDialog
struct PopupWebView {
  controller?: CustomDialogController;
  webViewController: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Web({ src: '', controller: this.webViewController })
      .javaScriptAccess(true)
      .multiWindowAccess(false)
      .onWindowExit(() => {
        if (this.controller) {
          this.controller.close();
        }
      })
  }
}
