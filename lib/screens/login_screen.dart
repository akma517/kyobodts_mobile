import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/push_message.dart';
import '../widgets/content_modal.dart';
import '../utils/push_test_helper.dart';
import '../services/api_service.dart';
import 'new_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _autoLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    try {
      print('LoginScreen: Checking auto login...');
      final success = await _authService.autoLogin();
      print('LoginScreen: Auto login result: $success');
      
      if (success && mounted) {
        print('LoginScreen: Auto login successful, navigating to home');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NewHomeScreen()),
        );
      } else {
        print('LoginScreen: Auto login failed or widget not mounted');
      }
    } catch (e) {
      print('LoginScreen: Auto login error: $e');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    print('LoginScreen._login: START - ID: ${_idController.text}, AutoLogin: $_autoLogin');
    setState(() => _isLoading = true);

    final success = await _authService.login(
      _idController.text,
      _passwordController.text,
      _autoLogin,
    );

    print('LoginScreen._login: Login result: $success');
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewHomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 4),
          dismissDirection: DismissDirection.down,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '교보DTS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('자동 로그인'),
                  value: _autoLogin,
                  onChanged: (value) {
                    setState(() => _autoLogin = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Test ID: test, PW: 1234',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: kDebugMode ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "test_api",
            mini: true,
            onPressed: _testApiCall,
            backgroundColor: Colors.green,
            child: const Icon(Icons.api),
          ),
          const SizedBox(height: 8),
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
      ) : null,
    );
  }

  void _showFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    
    print('🔥 저장된 FCM 토큰: $token');
    print('🔥 SharedPreferences 키들: ${prefs.getKeys()}');
    
    final displayToken = token?.isNotEmpty == true ? token! : '토큰이 없습니다\n\nFirebase 초기화가 완료되지 않았거나\n토큰 생성에 실패했습니다.';
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM 토큰'),
          content: SelectableText(displayToken),
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

  void _testApiCall() async {
    await ApiService.testApiCall();
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

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}