import { JavaScriptChannelFlutterApiImpl } from './JavaScriptChannelFlutterApiImpl';

export class JavaScriptChannel {
  private readonly flutterApi: JavaScriptChannelFlutterApiImpl;
  private readonly name: string;

  constructor(flutterApi: JavaScriptChannelFlutterApiImpl, name: string) {
    if (name == null || name.length == 0) {
      throw new Error('JavaScript channel name must not be empty.');
    }
    this.flutterApi = flutterApi;
    this.name = name;
  }

  getJavaScriptChannelName(): string {
    return this.name;
  }

  postMessage(message: string): void {
    this.flutterApi.postMessage(this, message, { reply: () => {} });
  }
}
