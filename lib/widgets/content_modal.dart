import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ContentModal extends StatefulWidget {
  final String contentUrl;
  final String title;
  final ContentType contentType;

  const ContentModal({
    super.key,
    required this.contentUrl,
    required this.title,
    required this.contentType,
  });

  @override
  State<ContentModal> createState() => _ContentModalState();
}

class _ContentModalState extends State<ContentModal> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildContent(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.contentType) {
      case ContentType.html:
        return _buildWebView();
      case ContentType.pdf:
        return _buildPdfView();
      case ContentType.asset:
        return _buildAssetView();
    }
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.contentUrl)),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStop: (controller, url) {
        setState(() => _isLoading = false);
      },
      onLoadError: (controller, url, code, message) {
        setState(() => _isLoading = false);
      },
    );
  }

  Widget _buildPdfView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.contentUrl)),
      initialSettings: InAppWebViewSettings(
        supportZoom: true,
        builtInZoomControls: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStop: (controller, url) {
        setState(() => _isLoading = false);
      },
    );
  }

  Widget _buildAssetView() {
    return FutureBuilder<String>(
      future: _loadAssetContent(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return InAppWebView(
            initialData: InAppWebViewInitialData(data: snapshot.data!),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String> _loadAssetContent() async {
    try {
      return await rootBundle.loadString(widget.contentUrl);
    } catch (e) {
      return '<html><body><h1>콘텐츠를 불러올 수 없습니다</h1></body></html>';
    }
  }
}

enum ContentType { html, pdf, asset }

class ContentModalHelper {
  static void showContentModal(
    BuildContext context, {
    required String contentUrl,
    required String title,
    ContentType contentType = ContentType.html,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContentModal(
        contentUrl: contentUrl,
        title: title,
        contentType: contentType,
      ),
    );
  }
}