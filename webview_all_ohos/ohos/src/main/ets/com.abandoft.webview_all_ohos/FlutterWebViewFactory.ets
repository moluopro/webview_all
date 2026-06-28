import common from '@ohos.app.ability.common';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import { InstanceManager } from './InstanceManager';

export class FlutterWebViewFactory extends PlatformViewFactory {
  private readonly instanceManager: InstanceManager;

  constructor(instanceManager: InstanceManager) {
    super(StandardMessageCodec.INSTANCE);
    this.instanceManager = instanceManager;
  }

  create(_context: common.Context, _viewId: number, args: ESObject): PlatformView {
    const identifier = args as number;
    if (identifier == null) {
      throw new Error('Platform view creation requires a WebView instance identifier.');
    }
    return this.instanceManager.getInstance<PlatformView>(identifier);
  }
}
