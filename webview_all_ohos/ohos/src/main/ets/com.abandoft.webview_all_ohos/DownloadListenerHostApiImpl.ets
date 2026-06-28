import { DownloadListenerFlutterApiImpl } from './DownloadListenerFlutterApiImpl';
import { InstanceManager } from './InstanceManager';

export interface DownloadListener {
  onDownloadStart(
    url: string,
    userAgent: string,
    contentDisposition: string,
    mimeType: string,
    contentLength: number
  ): void;
}

class OhosDownloadListener implements DownloadListener {
  private readonly flutterApi: DownloadListenerFlutterApiImpl;

  constructor(flutterApi: DownloadListenerFlutterApiImpl) {
    this.flutterApi = flutterApi;
  }

  onDownloadStart(
    url: string,
    userAgent: string,
    contentDisposition: string,
    mimeType: string,
    contentLength: number
  ): void {
    this.flutterApi.onDownloadStart(
      this,
      url,
      userAgent,
      contentDisposition,
      mimeType,
      contentLength,
      { reply: () => {} }
    );
  }
}

export class DownloadListenerCreator {
  createDownloadListener(flutterApi: DownloadListenerFlutterApiImpl): DownloadListener {
    return new OhosDownloadListener(flutterApi);
  }
}

export class DownloadListenerHostApiImpl {
  private readonly instanceManager: InstanceManager;
  private readonly creator: DownloadListenerCreator;
  private readonly flutterApi: DownloadListenerFlutterApiImpl;

  constructor(
    instanceManager: InstanceManager,
    creator: DownloadListenerCreator,
    flutterApi: DownloadListenerFlutterApiImpl
  ) {
    this.instanceManager = instanceManager;
    this.creator = creator;
    this.flutterApi = flutterApi;
  }

  create(instanceId: number): void {
    this.instanceManager.addDartCreatedInstance(
      this.creator.createDownloadListener(this.flutterApi),
      instanceId
    );
  }
}
