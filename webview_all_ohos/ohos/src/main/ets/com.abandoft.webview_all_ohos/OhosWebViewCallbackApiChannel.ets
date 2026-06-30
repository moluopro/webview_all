import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MethodChannel, { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';

const CHANNEL_NAME = 'com.abandoft.webview_all_ohos/callback_api';

export interface Reply<T> {
  reply: (value: T) => void;
}

export enum FileChooserMode {
  OPEN,
  OPEN_MULTIPLE,
  SAVE
}

export enum ConsoleMessageLevel {
  DEBUG,
  ERROR,
  LOG,
  TIP,
  WARNING,
  UNKNOWN
}

export interface CustomViewCallback {
  onCustomViewHidden(): void;
}

export interface HttpAuthHandler {
  cancel(): void;
  proceed(username: string, password: string): void;
  useHttpAuthUsernamePassword(): boolean;
}

export interface SslAuthHandler {
  cancel(): void;
  proceed(): void;
}

export class OhosWebViewCallbackApiChannel {
  private channel: MethodChannel;

  constructor(binaryMessenger: BinaryMessenger) {
    this.channel = new MethodChannel(binaryMessenger, CHANNEL_NAME);
  }

  invoke(method: string, args: ESObject, callback?: Reply<ESObject>): void {
    this.channel.invokeMethod(method, args, callback == null ? undefined : this.resultFor(callback));
  }

  createWebView(identifier: number, callback?: Reply<void>): void {
    this.invoke('WebView.create', new Map<string, ESObject>().set('identifier', identifier), callback);
  }

  onWebViewScrollChanged(
    webViewInstanceId: number,
    left: number,
    top: number,
    oldLeft: number,
    oldTop: number,
    callback?: Reply<void>
  ): void {
    this.invoke('WebView.onScrollChanged', new Map<string, ESObject>()
      .set('webViewInstanceId', webViewInstanceId)
      .set('left', left)
      .set('top', top)
      .set('oldLeft', oldLeft)
      .set('oldTop', oldTop), callback);
  }

  createFileChooserParams(
    instanceId: number,
    isCaptureEnabled: boolean,
    acceptTypes: string[],
    mode: FileChooserMode,
    filenameHint: string,
    callback?: Reply<void>
  ): void {
    this.invoke('FileChooserParams.create', new Map<string, ESObject>()
      .set('instanceId', instanceId)
      .set('isCaptureEnabled', isCaptureEnabled)
      .set('acceptTypes', acceptTypes)
      .set('mode', mode)
      .set('filenameHint', filenameHint), callback);
  }

  createPermissionRequest(identifier: number, resources: string[], callback?: Reply<void>): void {
    this.invoke('PermissionRequest.create', new Map<string, ESObject>()
      .set('identifier', identifier)
      .set('resources', resources), callback);
  }

  createCustomViewCallback(identifier: number, callback?: Reply<void>): void {
    this.invoke('CustomViewCallback.create', new Map<string, ESObject>().set('identifier', identifier), callback);
  }

  createView(identifier: number, callback?: Reply<void>): void {
    this.invoke('View.create', new Map<string, ESObject>().set('identifier', identifier), callback);
  }

  createGeolocationPermissionsCallback(instanceId: number, callback?: Reply<void>): void {
    this.invoke('GeolocationPermissionsCallback.create',
      new Map<string, ESObject>().set('instanceId', instanceId), callback);
  }

  createHttpAuthHandler(instanceId: number, callback?: Reply<void>): void {
    this.invoke('HttpAuthHandler.create', new Map<string, ESObject>().set('instanceId', instanceId), callback);
  }

  createSslAuthHandler(instanceId: number, callback?: Reply<void>): void {
    this.invoke('SslAuthHandler.create', new Map<string, ESObject>().set('instanceId', instanceId), callback);
  }

  private resultFor<T>(callback: Reply<T>): MethodResult {
    return {
      success: (result: ESObject): void => {
        callback.reply(result as T);
      },
      error: (errorCode: string, errorMessage: string, errorDetails: ESObject): void => {
        throw new Error(errorCode + ': ' + errorMessage + ', details=' + errorDetails);
      },
      notImplemented: (): void => {
        throw new Error('Dart callback method is not implemented.');
      }
    };
  }
}

export function emptyReply<T>(): Reply<T> {
  return {
    reply: (_value: T): void => {
    }
  };
}
