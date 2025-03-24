/*
 * Copyright (C) 2023-2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';

class WebviewWeb extends StatefulWidget {
  final String url;

  const WebviewWeb({super.key, required this.url});

  @override
  State<WebviewWeb> createState() => _WebviewWebState(url: url);
}

class _WebviewWebState extends State<WebviewWeb> {
  late String url;

  _WebviewWebState({required this.url});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
