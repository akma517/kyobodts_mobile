import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// main.dart에서 정의된 전역 변수 참조
external dynamic _globalAppState;

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onDynamicContentRequested;
  Function(Map<String, dynamic>)? onWebViewRequested;
  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('🔥 Firebase 이미 초기화됨');
      return;
    }
    
    if (_isInitializing) {
      print('🔥 Firebase 초기화 진행 중...');
      return;
    }
    
    _isInitializing = true;
    
    try {
      print('🔥 Firebase 서비스 초기화 시작...');
      print('🔥 플랫폼: ${defaultTargetPlatform.toString()}');
      
      // Firebase는 main()에서 이미 초기화됨
      print('🔥 Firebase 기본 초기화 확인 완료');
      
      // Firebase 초기화 후 messaging 인스턴스 생성
      _messaging = FirebaseMessaging.instance;
      print('📱 FirebaseMessaging 인스턴스 생성 완료');
      
      await _setupLocalNotifications();
      print('🔔 로컬 알림 설정 완료');
      
      await _requestPermissions();
      print('🔔 권한 요청 완료');
      
      await _setupMessageHandlers();
      print('📱 메시지 핸들러 설정 완료');
      
      await _getToken();
      print('🔥 Firebase 전체 초기화 완료!');
      
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('😨 Firebase 초기화 오류: $e');
      print('😨 스택 트레이스: $stackTrace');
      
      // 오류 유형별 상세 로깅
      if (e.toString().contains('GoogleService-Info.plist')) {
        print('😨 GoogleService-Info.plist 파일 문제 감지');
      } else if (e.toString().contains('duplicate')) {
        print('😨 중복 초기화 감지');
      } else if (e.toString().contains('network')) {
        print('😨 네트워크 연결 문제 감지');
      }
      
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupLocalNotifications() async {
    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'kyobodts_channel',
      '교보DTS 알림',
      description: '교보DTS 푸시 알림',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    print('🔔 로컬 알림 초기화 결과: $initialized');
    
    // 로컬 알림 권한 확인
    await _checkLocalNotificationPermissions();
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('🔔 FCM 권한 상태: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<void> _getToken() async {
    if (_messaging == null) return;
    
    try {
      String? token;
      
      if (Platform.isIOS) {
        print('🔥 iOS 플랫폼 - APNS 토큰 대기 중...');
        
        // APNS 토큰 대기 (최대 15초)
        for (int i = 0; i < 15; i++) {
          final apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) {
            print('🔥 APNS 토큰 획득 성공: ${apnsToken.substring(0, 20)}...');
            break;
          }
          print('🔥 APNS 토큰 대기 중... (${i + 1}/15)');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      // FCM 토큰 요청
      token = await _messaging!.getToken();
      
      if (token != null && token.isNotEmpty) {
        print('🔥 FCM Token 획득 성공: ${token.substring(0, 30)}...');
        print('🔥 전체 FCM Token: $token');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        print('🔥 토큰 SharedPreferences에 저장 완료');
      } else {
        print('🔥 FCM 토큰을 받지 못했습니다.');
      }
      
      // 전체 사용자 토픽 구독
      await _subscribeToTopics();
      
    } catch (e) {
      print('🔥 FCM 토큰 획득 실패: $e');
      if (e.toString().contains('apns-token-not-set')) {
        print('🔥 APNS 토큰이 설정되지 않았습니다. 실제 디바이스에서 테스트해주세요.');
      }
    }
  }
  
  Future<void> _subscribeToTopics() async {
    if (_messaging == null) return;
    
    try {
      // all_users 토픽은 로그인 시점에서 조건부 구독으로 변경
      // 추가 토픽들 (필요시)
      await _messaging!.subscribeToTopic('announcements');
      
    } catch (e) {
      // 토픽 구독 실패 시 무시
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 포그라운드 메시지 수신: ${message.notification?.title}');
    
    // 포그라운드에서는 로컬 알림만 표시
    _showLocalNotification(message);
    
    // 새로운 액션들은 포그라운드에서 웹뷰 열기 생략
    final action = message.data['action'];
    if (action == 'open_url' || action == 'show_dynamic_content') {
      print('📱 포그라운드에서 웹뷰 열기 생략: $action');
      // 기존 onMessageReceived 콜백만 호출 (인앱 알림 저장용)
      onMessageReceived?.call(message.data);
    } else {
      // 기존 액션들은 그대로 처리
      _processMessageData(message.data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 백그라운드 메시지 클릭: ${message.notification?.title}');
    print('📱 메시지 데이터: ${message.data}');
    
    // 전역 상태를 통해 직접 처리 시도
    try {
      if (_globalAppState != null) {
        print('📱 전역 상태를 통한 직접 처리');
        _globalAppState._processMessage(message.data);
        return;
      }
    } catch (e) {
      print('📱 전역 상태 처리 실패: $e');
    }
    
    print('📱 기존 콜백 체인 사용');
    _processMessageData(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      print('🔔 로컬 알림 표시 시작: ${message.notification?.title}');
      
      const androidDetails = AndroidNotificationDetails(
        'kyobodts_channel',
        '교보DTS 알림',
        channelDescription: '교보DTS 푸시 알림',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails, 
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _localNotifications.show(
        notificationId,
        message.notification?.title ?? '교보DTS',
        message.notification?.body ?? '',
        details,
        payload: jsonEncode(message.data),
      );
      
      print('🔔 로컬 알림 표시 완료: ID $notificationId');
    } catch (e) {
      print('❌ 로컬 알림 표시 실패: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _processMessageData(data);
    }
  }

  void _processMessageData(Map<String, dynamic> data) {
    // 기존 콜백 호출 (하위 호환성 보장)
    onMessageReceived?.call(data);
    
    // 동적 콘텐츠 액션 처리
    _handleDynamicContentAction(data);
  }
  
  void _handleDynamicContentAction(Map<String, dynamic> data) {
    try {
      final action = data['action'];
      print('🔥 동적 콘텐츠 액션 처리 시작: $action');
      
      if (action == 'show_dynamic_content') {
        final contentUrl = data['content_url'];
        final contentType = data['content_type'];
        
        if (contentUrl != null && contentType == 'dynamic_html') {
          print('🔥 동적 콘텐츠 액션 감지: $contentUrl');
          print('🔥 onDynamicContentRequested 콜백 호출 시도...');
          onDynamicContentRequested?.call({
            'content_url': contentUrl,
            'title': data['title'] ?? '알림',
          });
        }
      } else if (action == 'open_url') {
        final contentUrl = data['content_url'];
        
        if (contentUrl != null) {
          print('🔥 웹뷰 URL 액션 감지: $contentUrl');
          print('🔥 onWebViewRequested 콜백 호출 시도...');
          onWebViewRequested?.call({
            'url': contentUrl,
            'title': data['title'] ?? '알림',
          });
        }
      } else {
        print('🔥 알 수 없는 액션: $action');
      }
    } catch (e) {
      print('🔥 동적 콘텐츠 처리 오류: $e');
    }
  }
  
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  
  /// 푸시 알림 준비 상태 확인 (초기화 + 토큰 준비)
  Future<bool> isPushNotificationReady() async {
    if (!_isInitialized) {
      print('🔥 Firebase 초기화가 완료되지 않음');
      return false;
    }
    
    final fcmReady = await isFCMTokenReady();
    final apnsReady = await isAPNSTokenReady();
    
    final isReady = fcmReady && apnsReady;
    print('🔥 푸시 알림 준비 상태: ${isReady ? "준비됨" : "준비 안됨"} (FCM: $fcmReady, APNS: $apnsReady)');
    return isReady;
  }
  
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging != null) {
      await _messaging!.subscribeToTopic(topic);
      print('🔥 토픽 구독: $topic');
    }
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging != null) {
      await _messaging!.unsubscribeFromTopic(topic);
      print('🔥 토픽 구독 해제: $topic');
    }
  }
  
  /// APNS 토큰 준비 상태 확인 (iOS만)
  Future<bool> isAPNSTokenReady() async {
    if (!Platform.isIOS || _messaging == null) {
      return true; // Android나 초기화 안된 경우는 true 반환
    }
    
    try {
      final apnsToken = await _messaging!.getAPNSToken();
      final isReady = apnsToken != null;
      print('🔥 APNS 토큰 상태: ${isReady ? "준비됨" : "준비 안됨"} - $apnsToken');
      return isReady;
    } catch (e) {
      print('🔥 APNS 토큰 상태 확인 실패: $e');
      return false;
    }
  }
  
  /// FCM 토큰 준비 상태 확인
  Future<bool> isFCMTokenReady() async {
    if (_messaging == null) return false;
    
    try {
      final token = await _messaging!.getToken();
      final isReady = token != null && token.isNotEmpty;
      print('🔥 FCM 토큰 상태: ${isReady ? "준비됨" : "준비 안됨"}');
      return isReady;
    } catch (e) {
      print('🔥 FCM 토큰 상태 확인 실패: $e');
      return false;
    }
  }
  
  /// 로컬 알림 권한 확인
  Future<void> _checkLocalNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.areNotificationsEnabled() ?? false;
      print('🔔 Android 로컬 알림 권한: ${granted ? "허용됨" : "거부됨"}');
    } else if (Platform.isIOS) {
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
      print('🔔 iOS 로컬 알림 권한: ${granted ? "허용됨" : "거부됨"}');
    }
  }
}



@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('📱 백그라운드 메시지 수신: ${message.notification?.title}');
  
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAJHDPlvaKoR2FD_t6wyx_mPJYhyFh0guM',
        appId: '1:860019738433:android:804dc9750e2778a198c3c0',
        messagingSenderId: '860019738433',
        projectId: 'kyobodts-mobile',
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD-Y48wGPTCXBqQQ21jt-0md_g1qtHBtb0',
        appId: '1:860019738433:ios:29823a1d5f86f09398c3c0',
        messagingSenderId: '860019738433',
        projectId: 'kyobodts-mobile',
        iosBundleId: 'com.kyobodts.mobile',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  // 백그라운드에서는 메시지 데이터만 처리 (웹뷰는 앱 열릴 때 처리)
  print('📱 백그라운드 메시지 데이터: ${message.data}');
}