import web_webview from '@ohos.web.webview';
import { WebSettings } from './WebSettingsHostApiImpl';
import { WebViewPlatformView } from './WebViewPlatformView';

export class WebViewSettings implements WebSettings {
  private readonly webView: WebViewPlatformView;
  private defaultUserAgent: string = '';
  private domStorageEnabled: boolean = false;
  private javaScriptCanOpenWindows: boolean = false;
  private multipleWindowsEnabled: boolean = false;
  private backgroundColor: string = '';
  private javaScriptEnabled: boolean = false;
  private mediaRequiresUserGesture: boolean = false;
  private zoomEnabled: boolean = true;
  private overviewModeEnabled: boolean = false;
  private wideViewportEnabled: boolean = false;
  private fileAccessEnabled: boolean = true;
  private textZoomRatio: number = 0;
  private textZoomCallback?: (ratio: number) => void;
  private fullScreenRotateEnabled: boolean = false;

  constructor(webView: WebViewPlatformView) {
    this.webView = webView;
  }

  setDomStorageEnabled(flag: boolean): void {
    this.domStorageEnabled = flag;
  }

  getDomStorageEnabled(): boolean {
    return this.domStorageEnabled;
  }

  setJavaScriptCanOpenWindowsAutomatically(flag: boolean): void {
    this.javaScriptCanOpenWindows = flag;
  }

  getJavaScriptCanOpenWindowsAutomatically(): boolean {
    return this.javaScriptCanOpenWindows;
  }

  setSupportMultipleWindows(support: boolean): void {
    this.multipleWindowsEnabled = support;
  }

  getSupportMultipleWindows(): boolean {
    return this.multipleWindowsEnabled;
  }

  setBackgroundColor(color: number): void {
    this.backgroundColor = '#' + color.toString(16).padStart(8, '0');
  }

  getBackgroundColor(): string {
    return this.backgroundColor;
  }

  setJavaScriptEnabled(flag: boolean): void {
    this.javaScriptEnabled = flag;
  }

  getJavaScriptEnabled(): boolean {
    return this.javaScriptEnabled;
  }

  async setUserAgentString(userAgentString: string): Promise<void> {
    await this.webView.waitControllerAttached();
    this.webView.setCustomUserAgent(userAgentString);
    this.webView.getController().loadUrl(this.webView.getUrl());
  }

  setMediaPlaybackRequiresUserGesture(require: boolean): void {
    this.mediaRequiresUserGesture = require;
  }

  getMediaPlaybackRequiresUserGesture(): boolean {
    return this.mediaRequiresUserGesture;
  }

  setSupportZoom(support: boolean): void {
    this.zoomEnabled = support;
  }

  getSupportZoom(): boolean {
    return this.zoomEnabled;
  }

  setLoadWithOverviewMode(overview: boolean): void {
    this.overviewModeEnabled = overview;
  }

  getLoadWithOverviewMode(): boolean {
    return this.overviewModeEnabled;
  }

  setUseWideViewPort(use: boolean): void {
    this.wideViewportEnabled = use;
  }

  getUseWideViewPort(): boolean {
    return this.wideViewportEnabled;
  }

  setDisplayZoomControls(_enabled: boolean): void {
  }

  setBuiltInZoomControls(_enabled: boolean): void {
  }

  setAllowFileAccess(enabled: boolean): void {
    this.fileAccessEnabled = enabled;
  }

  getAllowFileAccess(): boolean {
    return this.fileAccessEnabled;
  }

  setTextZoom(textZoom: number): void {
    this.textZoomRatio = textZoom;
    if (this.textZoomCallback) {
      this.textZoomCallback(textZoom);
    }
  }

  getTextZoom(): number {
    return this.textZoomRatio;
  }

  async getUserAgentString(): Promise<string> {
    if (this.webView.userAgentString.length > 0) {
      return this.webView.userAgentString;
    }
    if (this.webView.isWebviewBinding) {
      await this.webView.waitControllerAttached();
      return this.webView.getController().getCustomUserAgent();
    }
    if (this.defaultUserAgent.length > 0) {
      return this.defaultUserAgent;
    }
    web_webview.WebviewController.initializeWebEngine();
    this.defaultUserAgent = web_webview.WebviewController.getDefaultUserAgent();
    return this.defaultUserAgent;
  }

  onTextZoomChanged(callback: (ratio: number) => void): void {
    this.textZoomCallback = callback;
  }

  setAllowFullScreenRotate(enabled: boolean): void {
    this.fullScreenRotateEnabled = enabled;
  }

  getAllowFullScreenRotate(): boolean {
    return this.fullScreenRotateEnabled;
  }
}
