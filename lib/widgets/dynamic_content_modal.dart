import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/dynamic_content_service.dart';

class DynamicContentModal extends StatefulWidget {
  final String apiUrl;
  final String title;

  const DynamicContentModal({
    super.key,
    required this.apiUrl,
    required this.title,
  });

  @override
  State<DynamicContentModal> createState() => _DynamicContentModalState();
}

class _DynamicContentModalState extends State<DynamicContentModal> {
  bool _isLoading = true;
  String? _htmlContent;
  String? _error;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      print('DynamicContentModal: Loading content from ${widget.apiUrl}');
      
      // URL 유효성 검증
      if (!DynamicContentService.isValidUrl(widget.apiUrl)) {
        throw Exception('유효하지 않은 URL입니다');
      }
      
      // 안전한 도메인 확인 (선택적)
      if (!DynamicContentService.isSafeDomain(widget.apiUrl)) {
        print('DynamicContentModal: Warning - URL not in safe domain list: ${widget.apiUrl}');
        // 경고만 출력하고 계속 진행 (필요시 차단 가능)
      }
      
      final content = await DynamicContentService.fetchAndOptimizeHtml(widget.apiUrl);
      
      if (mounted) {
        setState(() {
          _htmlContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DynamicContentModal: Error loading content - $e');
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _htmlContent = null;
    });
    
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          if (_isLoading)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          if (_error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: '다시 시도',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_htmlContent != null) {
      return _buildWebView();
    }

    return _buildEmptyWidget();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '콘텐츠를 불러오는 중...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.apiUrl,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '콘텐츠를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '알 수 없는 오류가 발생했습니다',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _htmlContent!,
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: true,
          disableContextMenu: false,
          supportZoom: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
          thirdPartyCookiesEnabled: false,
          allowFileAccess: false,
          allowContentAccess: false,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
          allowsBackForwardNavigationGestures: true,
        ),
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        print('DynamicContentModal: WebView load start - $url');
      },
      onLoadStop: (controller, url) {
        print('DynamicContentModal: WebView load stop - $url');
      },
      onLoadError: (controller, url, code, message) {
        print('DynamicContentModal: WebView load error - $code: $message');
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        print('DynamicContentModal: Navigation attempt to $url');
        
        // 외부 링크는 차단하고 현재 모달에서만 표시
        if (url != null && url.toString() != 'about:blank') {
          // 필요시 외부 브라우저로 열기
          // await launchUrl(url);
          return NavigationActionPolicy.CANCEL;
        }
        
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '표시할 콘텐츠가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}