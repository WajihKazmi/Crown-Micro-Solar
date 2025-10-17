import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class webviewscreen extends StatefulWidget {
  const webviewscreen({Key? key}) : super(key: key);

  @override
  State<webviewscreen> createState() => _webviewscreenState();
}

class _webviewscreenState extends State<webviewscreen> {
  late WebViewController controller;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                controller.reload();
              },
              icon: Icon(Icons.refresh))
        ],
        title: Text("Module's Network Settings"),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            color: Colors.amber,
            backgroundColor: Colors.black,
          ),
          Expanded(
            child: WebView(
              javascriptMode: JavascriptMode.unrestricted,
              initialUrl: "http://192.168.88.88/",
              onWebViewCreated: (controller) {
                this.controller = controller;
              },
              onProgress: (progress) => setState(() {
                this.progress = progress / 100;
              }),
              onPageStarted: (sa) {
                debugPrint("onPageStarted $sa ");
              },
              onPageFinished: (url) {
                debugPrint("onPageFinished $url");
              },
            ),
          ),
        ],
      ),
    );
  }
}
