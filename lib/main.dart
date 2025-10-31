import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/session_manager.dart';
import 'services/inapp_notification_service.dart';
import 'widgets/content_modal.dart';
import 'widgets/dynamic_content_modal.dart';
import 'widgets/webview_modal.dart';
import 'models/push_message.dart';
import 'themes/theme_provider.dart';

// 전역 메시지 처리 함수 
MyAppState? _globalAppState;

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
    
    // iOS getInitialMessage 처리 (앱 종료 상태에서 푸시로 실행된 경우)
    await _handleInitialMessage();
    
  } catch (e) {
    print('🔥 Firebase main() 초기화 실패: $e');
  }
  
  // 앱 시작 즉시 스플래시 제거
  FlutterNativeSplash.remove();
  
  runApp(const MyApp());
}

// 초기 메시지 처리 (iOS 핵심 기능)
Future<void> _handleInitialMessage() async {
  try {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🔥 초기 메시지 발견: ${initialMessage.notification?.title}');
      print('🔥 초기 메시지 데이터: ${initialMessage.data}');
      
      // 전역 변수에 저장하여 앱 시작 후 처리
      _pendingInitialMessage = initialMessage.data;
    } else {
      print('🔥 초기 메시지 없음');
    }
  } catch (e) {
    print('🔥 초기 메시지 확인 실패: $e');
  }
}

// 대기 중인 초기 메시지
Map<String, dynamic>? _pendingInitialMessage;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// 타입 정의
typedef MyAppState = _MyAppState;

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SessionManager.setNavigatorKey(_navigatorKey);
    
    // 전역 상태 등록
    _globalAppState = this;
    
    // 즉시 푸시 핸들링 설정 (핸들러 등록 시점 최적화)
    _setupPushHandling();
    print('📱 푸시 핸들링 즉시 설정 완룈');
    
    // Firebase 서비스 백그라운드 초기화
    _initializeFirebaseInBackground();
    
    // 대기 중인 초기 메시지 처리
    _processPendingInitialMessage();
  }
  
  @override
  void dispose() {
    _globalAppState = null;
    super.dispose();
  }

  void _initializeFirebaseInBackground() async {
    try {
      print('🔥 Firebase 서비스 초기화 시작...');
      await FirebaseService().initialize();
      print('🔥 Firebase 서비스 초기화 완료');
      
      await InAppNotificationService.initialize();
      print('🔔 InApp 알림 서비스 초기화 완료');
      
      print('✅ 모든 Firebase 서비스 초기화 완료');
    } catch (e) {
      print('❌ Firebase 서비스 초기화 실패: $e');
      print('❌ 스택 트레이스: ${e.toString()}');
      // Firebase 초기화 실패해도 앱은 계속 실행
    }
  }
  
  /// 대기 중인 초기 메시지 처리
  void _processPendingInitialMessage() async {
    if (_pendingInitialMessage != null) {
      print('🔥 대기 중인 초기 메시지 처리 시작...');
      
      // Context 준비를 위해 짧은 대기
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 메시지 처리
      _processMessage(_pendingInitialMessage!);
      
      // 처리 완료 후 제거
      _pendingInitialMessage = null;
    }
  }

  void _setupPushHandling() {
    try {
      print('📱 푸시 핸들링 콜백 등록 시작...');
      
      // 기존 메시지 처리 (하위 호환성 보장)
      FirebaseService().onMessageReceived = (data) {
        print('📱 onMessageReceived 콜백 호출: ${data['title']}');
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
      
      // 동적 콘텐츠 처리 (새로운 기능) - Context 안전성 보장
      FirebaseService().onDynamicContentRequested = (data) {
        print('📱 onDynamicContentRequested 콜백 호출: ${data['title']}');
        _safeShowDynamicContentModal(data);
      };
      
      // 웹뷰 URL 처리 (새로운 기능) - Context 안전성 보장
      FirebaseService().onWebViewRequested = (data) {
        print('📱 onWebViewRequested 콜백 호출: ${data['title']}');
        _safeShowWebViewModal(data);
      };
      
      print('📱 모든 푸시 콜백 등록 완료');
    } catch (e) {
      print('❌ Firebase 푸시 핸들링 설정 실패: $e');
    }
  }
  
  /// 통합 메시지 처리 함수 (getInitialMessage + onMessageOpenedApp)
  void _processMessage(Map<String, dynamic> data) {
    print('🔥 통합 메시지 처리 시작: ${data['title']}');
    
    final action = data['action'];
    if (action == 'open_url') {
      final contentUrl = data['content_url'];
      if (contentUrl != null) {
        print('🔥 웹뷰 URL 액션 감지: $contentUrl');
        _safeShowWebViewModal({
          'url': contentUrl,
          'title': data['title'] ?? '알림',
        });
      }
    } else if (action == 'show_dynamic_content') {
      final contentUrl = data['content_url'];
      final contentType = data['content_type'];
      if (contentUrl != null && contentType == 'dynamic_html') {
        print('🔥 동적 콘텐츠 액션 감지: $contentUrl');
        _safeShowDynamicContentModal({
          'content_url': contentUrl,
          'title': data['title'] ?? '알림',
        });
      }
    } else {
      print('🔥 알 수 없는 액션 또는 기존 처리: $action');
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
  
  /// Context 안전성을 보장하는 웹뷰 모달 표시
  void _safeShowWebViewModal(Map<String, dynamic> data) async {
    print('📱 웹뷰 모달 표시 시도: ${data['title']}');
    
    // Context 준비 대기 및 재시도 로직
    for (int attempt = 0; attempt < 5; attempt++) {
      final context = _navigatorKey.currentContext;
      
      if (context != null && mounted) {
        try {
          print('📱 Context 준비 완료, 모달 표시 (${attempt + 1}번째 시도)');
          
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebViewModal(
                url: data['url'],
                title: data['title'],
              ),
              fullscreenDialog: true,
            ),
          );
          return; // 성공 시 종료
        } catch (e) {
          print('📱 모달 표시 실패: $e');
        }
      }
      
      print('📱 Context 준비 중... (${attempt + 1}/5)');
      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1))); // 지수적 대기
    }
    
    print('📱 모달 표시 최종 실패 - Context 준비 안됨');
  }
  
  /// Context 안전성을 보장하는 동적 콘텐츠 모달 표시
  void _safeShowDynamicContentModal(Map<String, dynamic> data) async {
    print('📱 동적 콘텐츠 모달 표시 시도: ${data['title']}');
    
    // Context 준비 대기 및 재시도 로직
    for (int attempt = 0; attempt < 5; attempt++) {
      final context = _navigatorKey.currentContext;
      
      if (context != null && mounted) {
        try {
          print('📱 Context 준비 완료, 모달 표시 (${attempt + 1}번째 시도)');
          
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DynamicContentModal(
                contentUrl: data['content_url'],
                title: data['title'],
              ),
              fullscreenDialog: true,
            ),
          );
          return; // 성공 시 종료
        } catch (e) {
          print('📱 모달 표시 실패: $e');
        }
      }
      
      print('📱 Context 준비 중... (${attempt + 1}/5)');
      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1))); // 지수적 대기
    }
    
    print('📱 모달 표시 최종 실패 - Context 준비 안됨');
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
