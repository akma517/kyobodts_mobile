import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/session_manager.dart';
import 'services/inapp_notification_service.dart';
import 'widgets/content_modal.dart';
import 'widgets/dynamic_content_modal.dart';
import 'widgets/webview_modal.dart';
import 'models/push_message.dart';
import 'themes/theme_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Firebase 먼저 초기화
  try {
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyD-Y48wGPTCXBqQQ21jt-0md_g1qtHBtb0',
          appId: '1:860019738433:ios:29823a1d5f86f09398c3c0',
          messagingSenderId: '860019738433',
          projectId: 'kyobodts-mobile',
          iosBundleId: 'com.kyobodts.mobile',
        ),
      );
    } else if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAJHDPlvaKoR2FD_t6wyx_mPJYhyFh0guM',
          appId: '1:860019738433:android:804dc9750e2778a198c3c0',
          messagingSenderId: '860019738433',
          projectId: 'kyobodts-mobile',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print('🔥 Firebase main() 초기화 완료');
  } catch (e) {
    print('🔥 Firebase main() 초기화 실패: $e');
  }
  
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
    // Firebase 초기화 완료 대기
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      print('🔥 Firebase 서비스 초기화 시작...');
      await FirebaseService().initialize();
      print('🔥 Firebase 서비스 초기화 완료');
      
      await InAppNotificationService.initialize();
      print('🔔 InApp 알림 서비스 초기화 완료');
      
      _setupPushHandling();
      print('📱 푸시 핸들링 설정 완료');
      
      print('✅ 모든 Firebase 서비스 초기화 완료');
    } catch (e) {
      print('❌ Firebase 서비스 초기화 실패: $e');
      print('❌ 스택 트레이스: ${e.toString()}');
      // Firebase 초기화 실패해도 앱은 계속 실행
    }
  }

  void _setupPushHandling() {
    try {
      // 기존 메시지 처리 (하위 호환성 보장)
      FirebaseService().onMessageReceived = (data) {
        final message = PushMessage.fromMap(data);
        
        // 인앱 알림으로도 저장 (권한 차단 사용자 대응)
        InAppNotificationService.addNotification(
          title: message.title,
          body: message.body,
          contentUrl: message.contentUrl,
          contentType: message.contentTypeEnum,
          customData: data,
        );
        
        // 포그라운드에서는 새로운 액션들 모달 열기 생략
        // 백그라운드에서는 전용 콜백에서 처리
        if (message.hasContent && 
            message.action != 'open_url' && 
            message.action != 'show_dynamic_content') {
          _showContentModal(message);
        }
      };
      
      // 동적 콘텐츠 처리 (새로운 기능)
      FirebaseService().onDynamicContentRequested = (data) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DynamicContentModal(
                contentUrl: data['content_url'],
                title: data['title'],
              ),
              fullscreenDialog: true,
            ),
          );
        }
      };
      
      // 웹뷰 URL 처리 (새로운 기능)
      FirebaseService().onWebViewRequested = (data) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebViewModal(
                url: data['url'],
                title: data['title'],
              ),
              fullscreenDialog: true,
            ),
          );
        }
      };
    } catch (e) {
      print('Firebase 푸시 핸들링 설정 실패: $e');
    }
  }

  void _showContentModal(PushMessage message) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // 동적 콘텐츠는 별도 콜백에서 처리하므로 여기서는 제외
      
      // 기존 정적 콘텐츠 처리
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
