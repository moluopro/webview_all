import { DVModelParameters } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicView';

type DynamicRecord = Record<string, ESObject>;

export class DynamicUtils {
  static getParams(params: DVModelParameters, key: string): string | ESObject {
    return (params as DynamicRecord)[key];
  }

  static setParams(params: DVModelParameters, key: string, value: ESObject): void {
    (params as DynamicRecord)[key] = value;
  }
}

export class DVModelJson {
  compType: string;
  children: Array<ESObject>;
  attributes: ESObject;
  events: ESObject;
  build?: ESObject;

  constructor(
    compType: string,
    children: Array<ESObject>,
    attributes: ESObject,
    events: ESObject,
    build?: ESObject
  ) {
    this.compType = compType;
    this.children = children;
    this.attributes = attributes;
    this.events = events;
    this.build = build;
  }
}
