import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppInAppWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const AppInAppWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AppInAppWebViewScreen> createState() => _AppInAppWebViewScreenState();
}

class _AppInAppWebViewScreenState extends State<AppInAppWebViewScreen> {
  static const _navy = Color(0xFF16161D);
  static const _purple = Color(0xFF4A22F4);

  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 10;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _loadingProgress = 100);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x1A000000),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: _navy,
              size: 20,
            ),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2.5),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: const Color(0xFFEFEBF9),
                  valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                  minHeight: 2.5,
                ),
              )
            : null,
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EEFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: _purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load page',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : 'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _hasError = false);
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
