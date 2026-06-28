import { InstanceManager } from './InstanceManager';
import { JavaScriptChannel } from './JavaScriptChannel';
import { JavaScriptChannelFlutterApiImpl } from './JavaScriptChannelFlutterApiImpl';

export class JavaScriptChannelCreator {
  createJavaScriptChannel(
    flutterApi: JavaScriptChannelFlutterApiImpl,
    channelName: string
  ): JavaScriptChannel {
    return new JavaScriptChannel(flutterApi, channelName);
  }
}

export class JavaScriptChannelHostApiImpl {
  private readonly instanceManager: InstanceManager;
  private readonly creator: JavaScriptChannelCreator;
  private readonly flutterApi: JavaScriptChannelFlutterApiImpl;

  constructor(
    instanceManager: InstanceManager,
    creator: JavaScriptChannelCreator,
    flutterApi: JavaScriptChannelFlutterApiImpl
  ) {
    this.instanceManager = instanceManager;
    this.creator = creator;
    this.flutterApi = flutterApi;
  }

  create(instanceId: number, channelName: string): void {
    this.instanceManager.addDartCreatedInstance(
      this.creator.createJavaScriptChannel(this.flutterApi, channelName),
      instanceId
    );
  }
}
