import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/notification_subscription_service.dart';
import '../screens/login_screen.dart';
import 'notification_toggle_switch.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonAppBarState extends State<CommonAppBar> {
  bool _isRealAccountLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await SessionManager.isRealAccountLoggedIn();
    if (mounted) {
      setState(() {
        _isRealAccountLoggedIn = isLoggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      automaticallyImplyLeading: widget.showBackButton,
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: themeProvider.isDarkMode ? '라이트 모드' : '다크 모드',
            );
          },
        ),
        // 실제 계정 로그인 사용자에게만 알림 토글 표시 (test 계정 제외)
        if (_isRealAccountLoggedIn) const NotificationToggleSwitch(),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _showLogoutDialog(context),
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop(); // 다이얼로그 닫기
                
                try {
                  await AuthService().logout();
                  print('CommonAppBar: AuthService logout completed');
                  
                  // 알림 구독 상태 초기화
                  await NotificationSubscriptionService.resetAllSubscriptions();
                  print('CommonAppBar: Notification subscriptions reset');
                  
                  // 로그인 상태 업데이트
                  if (mounted) {
                    setState(() {
                      _isRealAccountLoggedIn = false;
                    });
                  }
                } catch (e) {
                  print('CommonAppBar: Logout process error: $e');
                } finally {
                  // 에러 여부와 관계없이 로그인 화면으로 이동
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(
                '로그아웃',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // 로그인 성공 후 호출되는 메서드
  void onLoginSuccess() {
    _checkLoginStatus();
  }
}