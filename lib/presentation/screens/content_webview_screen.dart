import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const ContentWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<ContentWebViewScreen> createState() => _ContentWebViewScreenState();
}

class _ContentWebViewScreenState extends State<ContentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    final uri = Uri.tryParse(widget.url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _error = 'رابط غير صالح';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onWebResourceError: (err) => setState(() => _error = err.description),
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_progress < 100)
                  LinearProgressIndicator(value: _progress / 100.0),
              ],
            ),
    );
  }
}

