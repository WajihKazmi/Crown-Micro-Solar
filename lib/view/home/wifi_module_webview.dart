import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WifiModuleWebView extends StatefulWidget {
  const WifiModuleWebView({super.key});

  @override
  State<WifiModuleWebView> createState() => _WifiModuleWebViewState();
}

class _WifiModuleWebViewState extends State<WifiModuleWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse('http://192.168.88.88/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi‑Fi Module'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
