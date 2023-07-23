import 'package:flutter/material.dart';
import 'package:webf/webf.dart';

class WebviewDesktop extends StatefulWidget {
  final String url;

  const WebviewDesktop({Key? key, required this.url}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<WebviewDesktop> createState() => _WebviewDesktopState(url: url);
}

class _WebviewDesktopState extends State<WebviewDesktop> {

  final String url;
  _WebviewDesktopState({required this.url});

  @override
  Widget build(BuildContext context) {
    final MediaQueryData queryData = MediaQuery.of(context);
    final Size viewportSize = queryData.size;
    return Column(
      children: [
        WebF(
          viewportWidth: viewportSize.width - queryData.padding.horizontal,
          viewportHeight: viewportSize.height - queryData.padding.vertical,
          bundle: WebFBundle.fromUrl(url),
        ),
      ],
    );
  }
}
