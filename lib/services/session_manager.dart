import 'package:flutter/material.dart';
import 'auth_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthService _authService = AuthService();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // HTML 응답 감지 시 세션 처리
  Future<bool> handleHtmlResponse() async {
    print('SessionManager.handleHtmlResponse: HTML response detected');
    
    // 자동로그인 설정 확인
    final hasAutoLogin = await _authService.hasAutoLoginCredentials;
    print('SessionManager.handleHtmlResponse: Has auto login credentials: $hasAutoLogin');
    
    if (hasAutoLogin) {
      print('SessionManager.handleHtmlResponse: Attempting re-login');
      final reLoginSuccess = await _authService.reLogin();
      
      if (reLoginSuccess) {
        print('SessionManager.handleHtmlResponse: Re-login successful');
        return true;
      } else {
        print('SessionManager.handleHtmlResponse: Re-login failed, redirecting to login');
        _redirectToLogin();
        return false;
      }
    } else {
      print('SessionManager.handleHtmlResponse: No auto login, redirecting to login');
      _redirectToLogin();
      return false;
    }
  }

  void _redirectToLogin() {
    if (_navigatorKey?.currentContext != null) {
      print('SessionManager._redirectToLogin: Navigating to login screen');
      Navigator.of(_navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }
}