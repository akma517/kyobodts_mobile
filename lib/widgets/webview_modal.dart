import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/dynamic_content_service.dart';

class WebViewModal extends StatefulWidget {
  final String url;
  final String title;

  const WebViewModal({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<WebViewModal> createState() => _WebViewModalState();
}

class _WebViewModalState extends State<WebViewModal> {
  bool _isLoading = true;
  String? _errorMessage;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _validateUrl();
  }

  void _validateUrl() {
    if (!DynamicContentService.isValidUrl(widget.url)) {
      setState(() {
        _errorMessage = '유효하지 않은 URL입니다';
        _isLoading = false;
      });
      return;
    }

    if (!DynamicContentService.isSafeDomain(widget.url)) {
      setState(() {
        _errorMessage = '허용되지 않은 도메인입니다';
        _isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'URL을 열 수 없습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _webViewController?.reload();
              },
              child: const Text('다시 시도'),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${widget.url}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              resourceCustomSchemes: [],
              allowUniversalAccessFromFileURLs: false,
              allowFileAccessFromFileURLs: false,
            ),
            android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
              allowsAirPlayForMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
            ),
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              _isLoading = true;
            });
          },
          onLoadStop: (controller, url) {
            setState(() {
              _isLoading = false;
            });
          },
          onReceivedError: (controller, request, error) {
            print('🚫 WebView 오류: ${error.description} (${error.type})');
            print('🚫 요청 URL: ${request.url}');
            
            setState(() {
              _isLoading = false;
              if (error.type == -1001) {
                _errorMessage = '서버 연결 시간이 초과되었습니다\n\n서버가 실행 중인지 확인해주세요';
              } else if (error.type == -1003) {
                _errorMessage = '서버를 찾을 수 없습니다\n\nURL을 확인해주세요';
              } else {
                _errorMessage = '페이지를 불러올 수 없습니다\n\n오류: ${error.description}';
              }
            });
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url.toString();
            if (DynamicContentService.isSafeDomain(url)) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        ),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('페이지를 불러오는 중...'),
              ],
            ),
          ),
      ],
    );
  }
}