import 'package:flutter/material.dart';
import 'package:abutil/abutil.dart';
import 'package:webview_all/webview_all.dart';

void main() {
  runApp(const BilibiliApp());
}

class BilibiliApp extends StatelessWidget {
  const BilibiliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilibili',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
      home: const BilibiliPage(),
    );
  }
}

class BilibiliPage extends StatefulWidget {
  const BilibiliPage({super.key});

  @override
  State<BilibiliPage> createState() => _BilibiliPageState();
}

class _BilibiliPageState extends State<BilibiliPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();

    if (!isWeb()) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _progress = progress;
                });
              }
            },
            onPageStarted: (String url) {
              debugPrint('Loading $url');
            },
            onPageFinished: (String url) {
              debugPrint('Finished $url');
              if (mounted) {
                setState(() {
                  _progress = 100;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint(
                'WebView error ${error.errorCode}: '
                '${error.description} (${error.url})',
              );
            },
          ),
        );
    }

    _controller.loadRequest(Uri.parse('https://www.bilibili.com'));
  }

  @override
  Widget build(BuildContext context) {
    final Widget webView = WebViewWidget(controller: _controller);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilibili'),
        actions: isWeb()
            ? const <Widget>[]
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      await _controller.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () async {
                    if (await _controller.canGoForward()) {
                      await _controller.goForward();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _controller.reload();
                  },
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: !isWeb() && _progress < 100
              ? LinearProgressIndicator(value: _progress / 100)
              : const SizedBox(height: 3),
        ),
      ),
      body: webView,
    );
  }
}
