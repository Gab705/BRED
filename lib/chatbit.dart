import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import spécifique pour Android
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import spécifique pour iOS
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Création du contrôleur WebView
    final platform = WebViewPlatform.instance;
    if (platform is WebKitWebViewPlatform) {
      // Configuration spécifique iOS - plus besoin de enableDebugging
      // Les options peuvent être configurées via WebKitWebViewPlatform
    }

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                debugPrint('Loading: $progress%');
              },
              onPageStarted: (String url) {
                debugPrint('Page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Page finished loading: $url');
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('Error: ${error.description}');
              },
            ),
          )
          ..loadRequest(
            Uri.parse('https://www.yeschat.ai/i/gpts-2OToO6J95F-AI-DOCTOR'),
          );

    // Configuration spécifique Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BRED Chat 🤖',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
