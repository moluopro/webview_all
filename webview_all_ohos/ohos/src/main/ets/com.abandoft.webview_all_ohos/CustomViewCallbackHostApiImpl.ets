import { CustomViewCallback } from './OhosWebViewCallbackApiChannel';
import { InstanceManager } from './InstanceManager';

export class CustomViewCallbackHostApiImpl {
  private readonly instanceManager: InstanceManager;

  constructor(_binaryMessenger: ESObject, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
  }

  onCustomViewHidden(identifier: number): void {
    this.callback(identifier).onCustomViewHidden();
  }

  private callback(identifier: number): CustomViewCallback {
    return this.instanceManager.getInstance<CustomViewCallback>(identifier);
  }
}
