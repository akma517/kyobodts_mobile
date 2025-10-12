import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/theme_provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      automaticallyImplyLeading: showBackButton,
      title: Text(
        title,
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
                Navigator.of(context).pop();
                try {
                  await AuthService().logout();
                } catch (e) {
                  print('로그아웃 API 호출 실패: $e');
                }
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}