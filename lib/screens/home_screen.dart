import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/webview_config.dart';
import '../services/webview_service.dart';
import '../services/preferences_service.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_floating_action_button.dart';
import '../widgets/popup_webview.dart';
import '../widgets/content_modal.dart';
import '../widgets/common_app_bar.dart';
import '../utils/push_test_helper.dart';
import '../models/push_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isAppLoading = true;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _preferencesService = PreferencesService();
  InAppWebViewController? _webViewController;
  bool _isLoginPage = false;
  bool _isInitialized = false;
  final Set<String> _autoLoginExecuted = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '교보DTS',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialSettings: WebViewConfig.getDefaultSettings(),
              initialUrlRequest: URLRequest(
                url: WebUri(AppConstants.GROUPWARE_LOGIN_URL),
              ),
              onCreateWindow: (controller, createWindowAction) async {
                if (defaultTargetPlatform == TargetPlatform.android) {
                  await _showPopupWebView(context, createWindowAction.windowId);
                }
                return null;
              },
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onLoadStop: (controller, url) => _handleLoadStop(url),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return _handleUrlLoading(navigationAction);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kDebugMode) ...[
            FloatingActionButton(
              heroTag: "show_token",
              mini: true,
              onPressed: _showFCMToken,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.token),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "test_push",
              mini: true,
              onPressed: _testPushNotification,
              child: const Icon(Icons.notifications),
            ),
          ],
          const SizedBox(height: 8),
          CustomFloatingActionButton(
            webViewController: _webViewController,
            isLoginPage: _isLoginPage,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        webViewController: _webViewController,
        onRefresh: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    
    // 초기 로그인 정보 로드
    await _preferencesService.getLoginInfo(AppConstants.GROUPWARE);
    await _preferencesService.getLoginInfo(AppConstants.GPRO);
    
    _isInitialized = true;
  }

  void _handleLoadStop(WebUri? url) async {
    if (url == null) return;
    
    final sURL = url.toString();
    final systemType = WebViewService.getSystemTypeFromUrl(sURL);
    final isLoginPage = WebViewService.isLoginPage(sURL);
    
    if (_isLoginPage != isLoginPage && mounted) {
      setState(() {
        _isLoginPage = isLoginPage;
      });
    }

    if (isAppLoading) {
      isAppLoading = false;
      FlutterNativeSplash.remove();
    }

    if (systemType != null) {
      final loginInfo = await _preferencesService.getLoginInfo(systemType);
      final loginKey = '$systemType-$sURL';
      
      if (loginInfo.isAutoLogin && !_autoLoginExecuted.contains(loginKey)) {
        _autoLoginExecuted.add(loginKey);
        WebViewService.executeAutoLogin(_webViewController!, systemType, loginInfo);
        
        // 로그인 성공 후 화면 새로고침으로 AppBar 상태 업데이트
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<NavigationActionPolicy> _handleUrlLoading(NavigationAction navigationAction) async {
    final uri = navigationAction.request.url!;

    if (!AppConstants.ALLOWED_URL_SCHEMES.contains(uri.scheme)) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return NavigationActionPolicy.CANCEL;
      }
    }

    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _showPopupWebView(BuildContext context, int windowId) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => PopupWebView(
          windowId: windowId,
          mainController: _webViewController!,
          onSplashRemove: (shouldRemove) {
            if (shouldRemove && isAppLoading) {
              isAppLoading = false;
              FlutterNativeSplash.remove();
            }
          },
        ),
      ),
    );
  }

  void _showFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token') ?? '토큰이 없습니다';
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM 토큰'),
          content: SelectableText(token),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  void _testPushNotification() async {
    final data = PushTestHelper.getSamplePushData();
    final message = PushMessage.fromMap(data);
    
    if (message.hasContent) {
      ContentType contentType;
      switch (message.contentTypeEnum) {
        case 'pdf':
          contentType = ContentType.pdf;
          break;
        case 'asset':
          contentType = ContentType.asset;
          break;
        default:
          contentType = ContentType.html;
      }

      ContentModalHelper.showContentModal(
        context,
        contentUrl: message.contentUrl!,
        title: message.title,
        contentType: contentType,
      );
    }
  }
}