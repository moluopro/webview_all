## Webview for All Flutter Platform  

[English Doc](https://github.com/moluopro/webview_all/blob/main/README.md) &nbsp;&nbsp;&nbsp;[中文文档](https://github.com/moluopro/webview_all/blob/main/README.ZH.md)  

支持所有Flutter平台的Webview组件 (基于社区现有的库)  

|| Platform | Status   | Note     |
|-| -------- | -------- | -------- |
|| Android  | ✅      | SDK 20+  |
|| IOS      | ✅      | SDK 9+   |
|| Web      | ✅      | Any      |
|| Windows  | ✅      | Win 7+   |
|| macOS    | ✅      | Any      |
|| Linux    | ✅      | Any      |

> ⚠：Linux和macOS平台还需要更多的测试。  

### 快速开始  

1. 将`webview_all`添加进[依赖](https://pub.dev/packages/webview_all/install) (`pubspec.yaml`文件).  

2. 直接像这样使用即可：   

```dart
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Webview All',
      debugShowCheckedModeBanner: false,
      home: MyBrowser(),
    );
  }
}

class MyBrowser extends StatefulWidget {
  const MyBrowser({Key? key, this.title}) : super(key: key);
  final String? title;
  
  @override
  _MyBrowserState createState() => _MyBrowserState();
}

class _MyBrowserState extends State<MyBrowser> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          // 看这里！  
          child: Webview(url: "https://www.wechat.com/en")
      )
    );
  }
}
```   

运行`flutter run -d windows`，然后您将看到:  

![example](https://s1.ax1x.com/2023/07/24/pCOJIN4.png)  
<br>

### Detail  

On iOS the Webview widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).  

On Android the Webview widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).  

On web the Webview widget will use the `webview_flutter_web` plugin.   

On desktop the Webview widget will use the `webf` plugin and only support less complex webpages.  