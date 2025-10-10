import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/webview_config.dart';
import '../services/webview_service.dart';
import '../services/preferences_service.dart';
import 'custom_bottom_navigation.dart';
import 'custom_floating_action_button.dart';

class PopupWebView extends StatefulWidget {
  final int windowId;
  final InAppWebViewController mainController;
  final Function(bool) onSplashRemove;

  const PopupWebView({
    super.key,
    required this.windowId,
    required this.mainController,
    required this.onSplashRemove,
  });

  @override
  State<PopupWebView> createState() => _PopupWebViewState();
}

class _PopupWebViewState extends State<PopupWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoginPage = false;
  final Set<String> _autoLoginExecuted = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              InAppWebView(
                initialSettings: WebViewConfig.getDefaultSettings(),
                windowId: widget.windowId,
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onCloseWindow: (controller) {
                  Navigator.pop(context);
                },
                onLoadStop: (controller, url) => _handleLoadStop(url),
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return _handleUrlLoading(navigationAction);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        webViewController: _webViewController,
        onRefresh: () => setState(() {}),
      ),
      floatingActionButton: CustomFloatingActionButton(
        webViewController: _webViewController,
        isLoginPage: _isLoginPage,
      ),
    );
  }

  void _handleLoadStop(WebUri? url) async {
    if (url == null) return;
    
    final sURL = url.toString();
    final systemType = WebViewService.getSystemTypeFromUrl(sURL);
    
    setState(() {
      _isLoginPage = WebViewService.isLoginPage(sURL);
    });

    widget.onSplashRemove(true);

    if (systemType != null) {
      final preferencesService = PreferencesService();
      final loginInfo = await preferencesService.getLoginInfo(systemType);
      final loginKey = '$systemType-$sURL';
      
      if (loginInfo.isAutoLogin && !_autoLoginExecuted.contains(loginKey)) {
        _autoLoginExecuted.add(loginKey);
        WebViewService.executeAutoLogin(_webViewController!, systemType, loginInfo);
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
}