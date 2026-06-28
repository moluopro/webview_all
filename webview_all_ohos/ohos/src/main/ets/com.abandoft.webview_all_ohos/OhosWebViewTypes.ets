export interface Result<T> {
  success(value: T): void;

  error(error: Error): void;
}

export interface WebViewPointBuilder {
  setX(value: number): WebViewPointBuilder;

  setY(value: number): WebViewPointBuilder;

  build(): WebViewPoint;
}

class MutableWebViewPointBuilder implements WebViewPointBuilder {
  private x: number = 0;
  private y: number = 0;

  setX(value: number): WebViewPointBuilder {
    this.x = value;
    return this;
  }

  setY(value: number): WebViewPointBuilder {
    this.y = value;
    return this;
  }

  build(): WebViewPoint {
    return new WebViewPoint(this.x, this.y);
  }
}

export class WebViewPoint {
  private x: number;
  private y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  static Builder(): WebViewPointBuilder {
    return new MutableWebViewPointBuilder();
  }

  getX(): number {
    return this.x;
  }

  getY(): number {
    return this.y;
  }

  toArray(): number[] {
    return [this.x, this.y];
  }
}
