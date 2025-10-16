import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/session_manager.dart';
import 'widgets/content_modal.dart';
import 'models/push_message.dart';
import 'themes/theme_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // 앱 시작 즉시 스플래시 제거
  FlutterNativeSplash.remove();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SessionManager.setNavigatorKey(_navigatorKey);
    _initializeFirebaseInBackground();
  }

  void _initializeFirebaseInBackground() async {
    // Firebase를 백그라운드에서 초기화
    try {
      await FirebaseService().initialize();
      _setupPushHandling();
      print('Firebase 백그라운드 초기화 완료');
    } catch (e) {
      print('Firebase 백그라운드 초기화 실패: $e');
    }
  }

  void _setupPushHandling() {
    try {
      FirebaseService().onMessageReceived = (data) {
        final message = PushMessage.fromMap(data);
        if (message.hasContent) {
          _showContentModal(message);
        }
      };
    } catch (e) {
      print('Firebase 푸시 핸들링 설정 실패: $e');
    }
  }

  void _showContentModal(PushMessage message) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: '교보DTS',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
