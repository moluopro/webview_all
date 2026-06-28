import { InstanceManager } from './InstanceManager';

export class GeolocationPermissionsCallbackHostApiImpl {
  private readonly instanceManager: InstanceManager;

  constructor(_binaryMessenger: ESObject, instanceManager: InstanceManager) {
    this.instanceManager = instanceManager;
  }

  invoke(instanceId: number, origin: string, allow: boolean, retain: boolean): void {
    this.callback(instanceId).invoke(origin, allow, retain);
  }

  private callback(instanceId: number): JsGeolocation {
    return this.instanceManager.getInstance<JsGeolocation>(instanceId);
  }
}
