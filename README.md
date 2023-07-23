# Webview for all Flutter Platform

A webview widget with full platform support, based on the existing package.  

|          |          |          |
| -------- | -------- | -------- |
| Android  | ✅       |SDK 20+   |
| IOS      | ✅       |SDK 9.0+  |
| Web      | ✅       | Any      |
| Linux    | ✅       |Not widely tested|
| macOS    | ✅       | WKWebview |
| Windows  | ✅       | Any      |

## Usage  

1. Add `webview_all` as a [dependency in your pubspec.yaml file](https://pub.dev/packages/webview_all/install).  

2. modify your `main.dart`.  

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
```   

3. launch webview  

```dart  
class _MyBrowserState extends State<MyBrowser> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(child: Webview(url: "https://www.baidu.com")));
  }
}
```  

## Detail  

On iOS the WebView widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).  

On Android the WebView widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).  

On web the WebView widget will use the `webview_flutter_web` plugin.   
> This plugin can't run for now and use url_launcher instead  

On desktop the WebView widget will use the webf plugin and only support simple webpage.  