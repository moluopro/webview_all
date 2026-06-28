import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { InstanceManager } from './InstanceManager';
import { OhosWebViewCallbackApiChannel, Reply } from './OhosWebViewCallbackApiChannel';

export class DownloadListenerFlutterApiImpl {
  private instanceManager: InstanceManager;
  private callbackApi: OhosWebViewCallbackApiChannel;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
    this.callbackApi = new OhosWebViewCallbackApiChannel(binaryMessenger);
  }

  onDownloadStart(
    downloadListener: DownloadListener,
    url: string,
    userAgent: string,
    contentDisposition: string,
    mimetype: string,
    contentLength: number,
    callback?: Reply<void>
  ): void {
    this.callbackApi.invoke('DownloadListener.onDownloadStart', new Map<string, ESObject>()
      .set('instanceId', this.getIdentifierForListener(downloadListener))
      .set('url', url)
      .set('userAgent', userAgent)
      .set('contentDisposition', contentDisposition)
      .set('mimetype', mimetype)
      .set('contentLength', contentLength), callback);
  }

  private getIdentifierForListener(listener: DownloadListener): number {
    const identifier = this.instanceManager.getIdentifier(listener);
    if (identifier == null) {
      throw new Error('Could not find identifier for DownloadListener.');
    }
    return identifier;
  }
}

export interface DownloadListener {
  onDownloadStart(url: string, userAgent: string, contentDisposition: string, mimeType: string, contentLength: number): void;
}
