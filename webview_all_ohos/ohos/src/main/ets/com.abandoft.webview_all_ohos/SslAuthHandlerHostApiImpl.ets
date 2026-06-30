import { SslAuthHandler } from './OhosWebViewCallbackApiChannel';
import { InstanceManager } from './InstanceManager';

export class SslAuthHandlerHostApiImpl {
  private readonly instanceManager: InstanceManager;

  constructor(_binaryMessenger: ESObject, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
  }

  cancel(instanceId: number): void {
    this.handler(instanceId).cancel();
  }

  proceed(instanceId: number): void {
    this.handler(instanceId).proceed();
  }

  private handler(instanceId: number): SslAuthHandler {
    return this.instanceManager.getInstance<SslAuthHandler>(instanceId);
  }
}
