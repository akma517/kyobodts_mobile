import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTopicManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String ALL_USERS_TOPIC = 'all_users';
  
  /// 조건부 all_users 토픽 구독 (최초 로그인 + 권한 허용 + 실제 계정)
  static Future<bool> subscribeToAllUsersIfEligible(String userId) async {
    try {
      // test 계정 제외
      if (userId == 'test') {
        return false;
      }
      
      // 최초 로그인 여부 확인
      final isFirstLogin = await _isFirstLogin(userId);
      if (!isFirstLogin) {
        return false;
      }
      
      // 알림 권한 확인
      final hasPermission = await _hasNotificationPermission();
      if (!hasPermission) {
        return false;
      }
      
      // 모든 조건 만족 시 구독
      await _messaging.subscribeToTopic(ALL_USERS_TOPIC);
      
      // 최초 로그인 완료 기록
      await _markFirstLoginComplete(userId);
      
      // 기존 상단바 토글 상태와 동기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('subscribed_all_users', true);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 알림 권한 확인
  static Future<bool> _hasNotificationPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }
  
  /// 최초 로그인 여부 확인
  static Future<bool> _isFirstLogin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'first_login_completed_$userId';
      return !prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }
  
  /// 최초 로그인 완료 기록
  static Future<void> _markFirstLoginComplete(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'first_login_completed_$userId';
      await prefs.setBool(key, true);
    } catch (e) {
      // 에러 시 무시
    }
  }
  
  /// 기본 all_users 토픽 구독 (기존 호환성)
  static Future<bool> subscribeToAllUsers() async {
    try {
      await _messaging.subscribeToTopic(ALL_USERS_TOPIC);
      return true;
    } catch (e) {
      return false;
    }
  }
}