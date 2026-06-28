import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { DVModel } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicView';
import { CustomViewCallbackFlutterApiImpl } from './CustomViewCallbackFlutterApiImpl';
import { FileChooserParamsFlutterApiImpl } from './FileChooserParamsFlutterApiImpl';
import { GeolocationPermissionsCallbackFlutterApiImpl } from './GeolocationPermissionsCallbackFlutterApiImpl';
import { InstanceManager } from './InstanceManager';
import {
  ConsoleMessageLevel,
  CustomViewCallback,
  OhosWebViewCallbackApiChannel,
  Reply,
  emptyReply
} from './OhosWebViewCallbackApiChannel';
import { PermissionRequestFlutterApiImpl } from './PermissionRequestFlutterApiImpl';
import { ViewFlutterApiImpl } from './ViewFlutterApiImpl';
import { WebChromeClient } from './WebChromeClientHostApiImpl';
import { WebViewFlutterApiImpl } from './WebViewFlutterApiImpl';
import { WebViewPlatformView } from './WebViewPlatformView';

export class WebChromeClientFlutterApiImpl {
  private binaryMessenger: BinaryMessenger;
  private instanceManager: InstanceManager;
  private webViewFlutterApi: WebViewFlutterApiImpl;
  private callbackApi: OhosWebViewCallbackApiChannel;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    this.webViewFlutterApi = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);
    this.callbackApi = new OhosWebViewCallbackApiChannel(binaryMessenger);
  }

  onProgressChangedImpl(
    webChromeClient: WebChromeClient,
    webView: WebViewPlatformView,
    progress: number,
    callback?: Reply<void>
  ): void {
    this.webViewFlutterApi.create(webView, emptyReply<void>());
    this.callbackApi.invoke('WebChromeClient.onProgressChanged', this.baseArgs(webChromeClient)
      .set('webViewInstanceId', this.instanceManager.getIdentifier(webView))
      .set('progress', progress), callback);
  }

  onShowFileChooserImpl(
    webChromeClient: WebChromeClient,
    webView: WebViewPlatformView,
    fileChooserParams: FileSelectorParam,
    callback: Reply<Array<string>>
  ): void {
    this.webViewFlutterApi.create(webView, emptyReply<void>());
    new FileChooserParamsFlutterApiImpl(this.binaryMessenger, this.instanceManager)
      .create(fileChooserParams, emptyReply<void>());

    this.callbackApi.invoke('WebChromeClient.onShowFileChooser', this.baseArgs(webChromeClient)
      .set('webViewInstanceId', this.instanceManager.getIdentifier(webView))
      .set('paramsInstanceId', this.instanceManager.getIdentifier(fileChooserParams)), callback);
  }

  onGeolocationPermissionsShowPromptImpl(
    webChromeClient: WebChromeClient,
    origin: string,
    callback: JsGeolocation,
    replyCallback?: Reply<void>
  ): void {
    new GeolocationPermissionsCallbackFlutterApiImpl(this.binaryMessenger, this.instanceManager)
      .create(callback, emptyReply<void>());

    this.callbackApi.invoke('WebChromeClient.onGeolocationPermissionsShowPrompt', this.baseArgs(webChromeClient)
      .set('paramsInstanceId', this.instanceManager.getIdentifier(callback))
      .set('origin', origin), replyCallback);
  }

  onGeolocationPermissionsHidePromptImpl(instance: WebChromeClient, callback?: Reply<void>): void {
    this.callbackApi.invoke('WebChromeClient.onGeolocationPermissionsHidePrompt',
      new Map<string, ESObject>().set('identifier', this.instanceManager.getIdentifier(instance)), callback);
  }

  onPermissionRequestImpl(
    instance: WebChromeClient,
    request: PermissionRequest,
    callback?: Reply<void>
  ): void {
    new PermissionRequestFlutterApiImpl(this.binaryMessenger, this.instanceManager)
      .create(request, request.getAccessibleResource(), emptyReply<void>());

    this.callbackApi.invoke('WebChromeClient.onPermissionRequest', this.baseArgs(instance)
      .set('requestInstanceId', this.instanceManager.getIdentifier(request)), callback);
  }

  onShowCustomViewImpl(
    instance: WebChromeClient,
    view: DVModel,
    customViewCallback: CustomViewCallback,
    callback?: Reply<void>
  ): void {
    new ViewFlutterApiImpl(this.binaryMessenger, this.instanceManager).create(view, emptyReply<void>());
    new CustomViewCallbackFlutterApiImpl(this.binaryMessenger, this.instanceManager)
      .create(customViewCallback, emptyReply<void>());

    this.callbackApi.invoke('WebChromeClient.onShowCustomView', this.baseArgs(instance)
      .set('viewIdentifier', this.instanceManager.getIdentifier(view))
      .set('callbackIdentifier', this.instanceManager.getIdentifier(customViewCallback)), callback);
  }

  onHideCustomViewImpl(instance: WebChromeClient, callback?: Reply<void>): void {
    this.callbackApi.invoke('WebChromeClient.onHideCustomView', this.baseArgs(instance), callback);
  }

  onConsoleMessageImpl(
    instance: WebChromeClient,
    message: ConsoleMessage,
    callback?: Reply<void>
  ): void {
    this.callbackApi.invoke('WebChromeClient.onConsoleMessage', this.baseArgs(instance)
      .set('message', new Map<string, ESObject>()
        .set('lineNumber', message.getLineNumber())
        .set('message', message.getMessage())
        .set('level', this.toConsoleMessageLevel(message.getMessageLevel()))
        .set('sourceId', message.getSourceId())), callback);
  }

  onJsAlertImpl(
    instance: WebChromeClient,
    url: string,
    message: string,
    callback?: Reply<void>
  ): void {
    this.callbackApi.invoke('WebChromeClient.onJsAlert', this.baseArgs(instance)
      .set('url', url)
      .set('message', message), callback);
  }

  onJsConfirmImpl(
    instance: WebChromeClient,
    url: string,
    message: string,
    callback: Reply<boolean | null>
  ): void {
    this.callbackApi.invoke('WebChromeClient.onJsConfirm', this.baseArgs(instance)
      .set('url', url)
      .set('message', message), callback);
  }

  onJsPromptImpl(
    instance: WebChromeClient,
    url: string,
    message: string,
    defaultValue: string,
    callback: Reply<string | null>
  ): void {
    this.callbackApi.invoke('WebChromeClient.onJsPrompt', this.baseArgs(instance)
      .set('url', url)
      .set('message', message)
      .set('defaultValue', defaultValue), callback);
  }

  private baseArgs(webChromeClient: WebChromeClient): Map<string, ESObject> {
    return new Map<string, ESObject>().set('instanceId', this.getIdentifierForClient(webChromeClient));
  }

  private getIdentifierForClient(webChromeClient: WebChromeClient): number {
    const identifier: number = this.instanceManager.getIdentifier(webChromeClient);
    if (identifier == null) {
      throw new Error('Could not find identifier for WebChromeClient.');
    }
    return identifier;
  }

  private toConsoleMessageLevel(level: MessageLevel): ConsoleMessageLevel {
    switch (level) {
      case MessageLevel.Info:
        return ConsoleMessageLevel.TIP;
      case MessageLevel.Log:
        return ConsoleMessageLevel.LOG;
      case MessageLevel.Warn:
        return ConsoleMessageLevel.WARNING;
      case MessageLevel.Error:
        return ConsoleMessageLevel.ERROR;
      case MessageLevel.Debug:
        return ConsoleMessageLevel.DEBUG;
      default:
        return ConsoleMessageLevel.UNKNOWN;
    }
  }
}
