import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';

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
        await _logoutAndRedirect();
        return false;
      }
    } else {
      print('SessionManager.handleHtmlResponse: No auto login, redirecting to login');
      await _logoutAndRedirect();
      return false;
    }
  }

  // 로그아웃 후 로그인 화면으로 이동
  Future<void> _logoutAndRedirect() async {
    try {
      await _authService.logout();
    } catch (e) {
      print('SessionManager._logoutAndRedirect: Logout error: $e');
    } finally {
      _redirectToLogin();
    }
  }

  // 로그인 화면으로 이동
  void _redirectToLogin() {
    if (_navigatorKey?.currentContext != null) {
      print('SessionManager._redirectToLogin: Navigating to login screen');
      final context = _navigatorKey!.currentContext!;
      
      // 세션 만료 토스트 표시
      _showSessionExpiredToast(context);
      
      // 비동기로 네비게이션 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      });
    } else {
      print('SessionManager._redirectToLogin: No navigator context available');
    }
  }
  
  // 세션 만료 토스트 표시
  void _showSessionExpiredToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '세션이 만료되었습니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  // 쿠키 가져오기
  static Future<String> getCookies() async {
    final instance = SessionManager();
    return await instance._authService.getCookies();
  }

  // 전역 로그아웃 처리 (어디서든 호출 가능)
  static Future<void> globalLogout() async {
    final instance = SessionManager();
    await instance._logoutAndRedirect();
  }
}