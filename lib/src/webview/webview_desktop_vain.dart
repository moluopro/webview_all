// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';

class WebviewDesktop extends StatefulWidget {
  final String url;

  const WebviewDesktop({Key? key, required this.url}) : super(key: key);

  @override
  State<WebviewDesktop> createState() => _WebviewDesktopState(url: url);
}

class _WebviewDesktopState extends State<WebviewDesktop> {

  final String url;
  _WebviewDesktopState({required this.url});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
      ],
    );
  }
}
