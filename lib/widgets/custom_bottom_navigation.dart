import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants/app_constants.dart';
import '../models/login_info.dart';
import '../services/preferences_service.dart';
import 'login_form_dialog.dart';

class CustomBottomNavigation extends StatelessWidget {
  final InAppWebViewController? webViewController;
  final VoidCallback? onRefresh;

  const CustomBottomNavigation({
    super.key,
    this.webViewController,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => webViewController?.goBack(),
            child: const Icon(Icons.arrow_back_ios),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => webViewController?.goForward(),
            child: const Icon(Icons.arrow_forward_ios),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _navigateToHome(),
            child: const Icon(Icons.home, size: 30)
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showLoginDialog(context, AppConstants.GROUPWARE),
            child: const Icon(Icons.info, size: 25),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showLoginDialog(context, AppConstants.GPRO),
            child: const Icon(Icons.g_mobiledata, size: 40),
          ),
          label: '',
        )
      ],
      selectedItemColor: Colors.black54,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
    );
  }

  void _navigateToHome() {
    webViewController?.getUrl().then((url) {
      var sURL = url.toString();
      if (!sURL.contains(AppConstants.GROUPWARE_LOGIN_URL)) {
        webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(AppConstants.GROUPWARE_MAIN_URL),
          ),
        );
      }
    });
  }

  void _showLoginDialog(BuildContext context, String systemType) async {
    final preferencesService = PreferencesService();
    final loginInfo = await preferencesService.getLoginInfo(systemType);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => LoginFormDialog(
          systemType: systemType,
          initialLoginInfo: loginInfo,
          onSaved: onRefresh,
        ),
      );
    }
  }
}