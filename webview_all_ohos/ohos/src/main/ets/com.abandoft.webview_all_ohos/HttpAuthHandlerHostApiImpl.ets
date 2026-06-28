import { HttpAuthHandler } from './OhosWebViewCallbackApiChannel';
import { InstanceManager } from './InstanceManager';

export class HttpAuthHandlerHostApiImpl {
  private readonly instanceManager: InstanceManager;

  constructor(_binaryMessenger: ESObject, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
  }

  useHttpAuthUsernamePassword(instanceId: number): boolean {
    return this.handler(instanceId).useHttpAuthUsernamePassword();
  }

  cancel(instanceId: number): void {
    this.handler(instanceId).cancel();
  }

  proceed(instanceId: number, username: string, password: string): void {
    this.handler(instanceId).proceed(username, password);
  }

  private handler(instanceId: number): HttpAuthHandler {
    return this.instanceManager.getInstance<HttpAuthHandler>(instanceId);
  }
}
