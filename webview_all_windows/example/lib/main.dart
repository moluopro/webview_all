import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_windows/webview_all_windows.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await WindowsWebViewController.initializeEnvironment();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ExampleBrowser());
  }
}

class ExampleBrowser extends StatefulWidget {
  const ExampleBrowser({super.key});

  @override
  State<ExampleBrowser> createState() => _ExampleBrowserState();
}

class _ExampleBrowserState extends State<ExampleBrowser> {
  late final WebViewController _controller;
  bool _isSuspended = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    var params = const PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WindowsWebViewPlatform) {
      params = const WindowsWebViewControllerCreationParams(
        popupWindowPolicy: WindowsPopupWindowPolicy.deny,
      );
    }

    _controller =
        WebViewController.fromPlatformCreationParams(
            params,
            onPermissionRequest: (WebViewPermissionRequest request) {
              request.deny();
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                if (mounted) {
                  setState(() {
                    _progress = progress;
                  });
                }
              },
            ),
          )
          ..setBackgroundColor(Colors.transparent)
          ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  @override
  Widget build(BuildContext context) {
    final windowsController = _controller.platform as WindowsWebViewController;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isSuspended) {
            await windowsController.resume();
          } else {
            await windowsController.suspend();
          }
          if (mounted) {
            setState(() {
              _isSuspended = !_isSuspended;
            });
          }
        },
        child: Icon(_isSuspended ? Icons.play_arrow : Icons.pause),
      ),
      appBar: AppBar(
        title: const Text('webview_all_windows'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(value: _progress / 100),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              windowsController.openDevTools();
            },
            icon: const Icon(Icons.developer_mode),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
