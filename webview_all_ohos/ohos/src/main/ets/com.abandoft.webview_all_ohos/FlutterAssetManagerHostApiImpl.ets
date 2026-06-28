import { FlutterAssetManager } from './FlutterAssetManager';

export class FlutterAssetManagerHostApiImpl {
  private readonly assets: FlutterAssetManager;

  constructor(assets: FlutterAssetManager) {
    this.assets = assets;
  }

  async list(path: string): Promise<string[]> {
    try {
      return await this.assets.list(path);
    } catch (_error) {
      return [];
    }
  }

  getAssetFilePathByName(name: string): string {
    return this.assets.getAssetFilePathByName(name);
  }
}
