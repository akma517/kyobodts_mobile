import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/dynamic_content_service.dart';

class DynamicContentModal extends StatefulWidget {
  final String contentUrl;
  final String title;

  const DynamicContentModal({
    Key? key,
    required this.contentUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<DynamicContentModal> createState() => _DynamicContentModalState();
}

class _DynamicContentModalState extends State<DynamicContentModal> {
  bool _isLoading = true;
  String? _htmlContent;
  String? _errorMessage;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      if (!DynamicContentService.isValidUrl(widget.contentUrl)) {
        throw Exception('유효하지 않은 URL입니다');
      }

      if (!DynamicContentService.isSafeDomain(widget.contentUrl)) {
        throw Exception('허용되지 않은 도메인입니다');
      }

      final htmlContent = await DynamicContentService.fetchHtmlContent(widget.contentUrl);
      
      if (mounted) {
        setState(() {
          _htmlContent = htmlContent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('콘텐츠를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '콘텐츠를 불러올 수 없습니다',
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
                _loadContent();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return InAppWebView(
      initialData: InAppWebViewInitialData(data: _htmlContent!),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          javaScriptEnabled: false, // 보안을 위해 JavaScript 비활성화
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        // 외부 링크 클릭 방지
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}