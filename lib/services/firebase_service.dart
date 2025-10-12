import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Function(Map<String, dynamic>)? onMessageReceived;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('🔥 Firebase 이미 초기화됨');
      return;
    }
    
    try {
      print('🔥 Firebase 초기화 시작...');
      
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
      
      print('🔥 Firebase 초기화 완료');
      
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
    } catch (e) {
      print('😨 Firebase 초기화 오류: $e');
      rethrow;
    }
  }

  Future<void> _setupLocalNotifications() async {
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

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
    } catch (e) {
      print('🔥 FCM 토큰 획득 실패: $e');
      if (e.toString().contains('apns-token-not-set')) {
        print('🔥 APNS 토큰이 설정되지 않았습니다. 실제 디바이스에서 테스트해주세요.');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 포그라운드 메시지 수신: ${message.notification?.title}');
    _showLocalNotification(message);
    _processMessageData(message.data);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _processMessageData(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'kyobodts_channel',
      '교보DTS 알림',
      channelDescription: '교보DTS 푸시 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '교보DTS',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _processMessageData(data);
    }
  }

  void _processMessageData(Map<String, dynamic> data) {
    onMessageReceived?.call(data);
  }
}



@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
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
}