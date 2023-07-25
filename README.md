## Webview for All Flutter Platform  

[English Doc](https://github.com/moluopro/webview_all/blob/main/README.md) &nbsp;&nbsp;&nbsp;[中文文档](https://github.com/moluopro/webview_all/blob/main/README.ZH.md)  

a webview widget with full-platform support, based on the existing packages  

| Platform | Status   | Note     |  
| -------- | -------- | -------- |  
| Android  | ✅      | SDK 20+  |  
| IOS      | ✅      | SDK 9+   |  
| Web      | ✅      | Any      |  
| Windows  | ✅      | Win 7+   |  
| macOS    | ✅      | Any      |  
| Linux    | ✅      | Any      |  

> ⚠: Linux and macOS platforms require more testing.  

### Quick Start  

1. Add `webview_all` as a [dependency](https://pub.dev/packages/webview_all/install) in your `pubspec.yaml` file.  

2. Just use it:   

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
          // Look here!  
          child: Webview(url: "https://www.wechat.com/en")
      )
    );
  }
}
```   

Run `flutter run -d windows`, then you will see:  

![example](https://s1.ax1x.com/2023/07/24/pCOJIN4.png)  
<br>

### Detail  

On iOS the Webview widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).  

On Android the Webview widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).  

On web the Webview widget will use the `webview_flutter_web` plugin.   

On desktop the Webview widget will use the `webf` plugin and only support less complex webpages.  