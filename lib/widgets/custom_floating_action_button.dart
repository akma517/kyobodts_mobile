import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants/app_constants.dart';
import '../models/login_info.dart';
import '../services/webview_service.dart';
import '../services/preferences_service.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final InAppWebViewController? webViewController;
  final bool isLoginPage;

  const CustomFloatingActionButton({
    super.key,
    this.webViewController,
    required this.isLoginPage,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handleButtonPress(),
      tooltip: 'autoLogin',
      child: Icon(isLoginPage ? Icons.login : Icons.refresh),
    );
  }

  void _handleButtonPress() {
    webViewController?.getUrl().then((url) async {
      var sURL = url.toString();
      final systemType = WebViewService.getSystemTypeFromUrl(sURL);
      
      if (systemType != null) {
        final preferencesService = PreferencesService();
        final loginInfo = await preferencesService.getLoginInfo(systemType);
        
        if (loginInfo.isAutoLogin) {
          WebViewService.executeAutoLogin(webViewController!, systemType, loginInfo);
        }
      } else {
        _refreshWebView();
      }
    });
  }

  void _refreshWebView() {
    if (kIsWeb) {
      return;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      webViewController?.reload();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      webViewController?.getUrl().then((url) {
        if (url != null) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: url));
        }
      });
    }
  }
}