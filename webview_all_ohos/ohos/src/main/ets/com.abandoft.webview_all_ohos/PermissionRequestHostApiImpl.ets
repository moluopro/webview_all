import { InstanceManager } from './InstanceManager';

export class PermissionRequestHostApiImpl {
  private readonly instanceManager: InstanceManager;

  constructor(_binaryMessenger: ESObject, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
  }

  grant(instanceId: number, resources: string[]): void {
    this.request(instanceId).grant(resources);
  }

  deny(instanceId: number): void {
    this.request(instanceId).deny();
  }

  private request(instanceId: number): PermissionRequest {
    return this.instanceManager.getInstance<PermissionRequest>(instanceId);
  }
}
