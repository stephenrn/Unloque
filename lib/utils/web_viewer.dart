import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeWebViewer extends StatefulWidget {
  final String url;
  final String title;

  const SafeWebViewer({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<SafeWebViewer> createState() => _SafeWebViewerState();
}

class _SafeWebViewerState extends State<SafeWebViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Error: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      );

      await controller.loadRequest(Uri.parse(widget.url));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Platform error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _controller != null && !_hasError
                ? () {
                    _controller!.reload();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () async {
              try {
                final uri = Uri.parse(widget.url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Could not open external browser: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null && !_hasError)
            WebViewWidget(controller: _controller!),
          if (_isLoading && !_hasError)
            Center(child: CircularProgressIndicator()),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load the web content',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(Icons.launch),
                      label: Text('Open in external browser'),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(widget.url);
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Could not open external browser: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
