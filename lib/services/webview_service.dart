import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants/app_constants.dart';
import '../models/login_info.dart';

class WebViewService {
  static void executeAutoLogin(InAppWebViewController controller, String systemType, LoginInfo loginInfo) {
    switch (systemType) {
      case AppConstants.GROUPWARE:
        controller.evaluateJavascript(
          source: "document.querySelector('#j_username').value = '${loginInfo.id}'"
        );
        controller.evaluateJavascript(
          source: "document.querySelector('#j_password').value = '${loginInfo.password}'"
        );
        controller.evaluateJavascript(
          source: "document.loginForm.submit()"
        );
        break;
      case AppConstants.GPRO:
        controller.evaluateJavascript(
          source: "document.querySelector('#email-address').value = '${loginInfo.id}'"
        );
        controller.evaluateJavascript(
          source: "document.querySelector('#password').value = '${loginInfo.password}'"
        );
        controller.evaluateJavascript(
          source: "document.querySelector(\"input[type='submit']\").click()"
        );
        break;
    }
  }

  static bool isLoginPage(String url) {
    return url.contains(AppConstants.GROUPWARE_LOGIN_URL) ||
           url.contains(AppConstants.GPRO_LOGIN_URL1) ||
           url.contains(AppConstants.GPRO_LOGIN_URL2);
  }

  static String? getSystemTypeFromUrl(String url) {
    if (url.contains(AppConstants.GROUPWARE_LOGIN_URL)) {
      return AppConstants.GROUPWARE;
    } else if (url.contains(AppConstants.GPRO_LOGIN_URL1) || 
               url.contains(AppConstants.GPRO_LOGIN_URL2)) {
      return AppConstants.GPRO;
    }
    return null;
  }
}