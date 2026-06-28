import resourceManager from '@ohos.resourceManager';
import { FlutterAssets } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';

export interface FlutterAssetManager {
  list(path: string): Promise<string[]>;

  getAssetFilePathByName(name: string): string;
}

export class PluginBindingFlutterAssetManager implements FlutterAssetManager {
  private readonly resources: resourceManager.ResourceManager;
  private readonly flutterAssets: FlutterAssets;

  constructor(resources: resourceManager.ResourceManager, flutterAssets: FlutterAssets) {
    this.resources = resources;
    this.flutterAssets = flutterAssets;
  }

  async list(path: string): Promise<string[]> {
    return this.resources.getRawFileList(path);
  }

  getAssetFilePathByName(name: string): string {
    return this.flutterAssets.getAssetFilePathByName(name);
  }
}
