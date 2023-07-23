## Webview for All Flutter Platform  

[English Doc](https://github.com/moluopro/webview_all/blob/main/README.md) &nbsp;&nbsp;&nbsp;[中文文档](https://github.com/moluopro/webview_all/blob/main/README.ZH.md)  

支持所有Flutter平台的Webview组件(基于社区现有的库)  

|          |          |          |
| -------- | -------- | -------- |
| Android  | ✅       |SDK 20+   |
| IOS      | ✅       |SDK 9.0+  |
| Web      | ✅       | Any      |
| Linux    | ✅       |Not widely tested|
| macOS    | ✅       |Not widely tested|
| Windows  | ✅       | Any      |

### 快速开始  

1. 将`webview_all`添加进[依赖](https://pub.dev/packages/webview_all/install) (`pubspec.yaml`文件).  
> flutter pub add webview_all  

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
          child: Webview(url: "https://www.baidu.com")
      )
    );
  }
}
```   

### 细节  

On iOS the WebView widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).  

On Android the WebView widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).  

On web the WebView widget will use the `webview_flutter_web` plugin.   
> This official plugin from Flutter is not working at the moment, so we are using `url_launcher` plugin instead. We will update `webview_all` as soon as the bug is fixed.  

On desktop the WebView widget will use the `webf` plugin and only support simple webpage.  