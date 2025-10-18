import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class NotificationSubscriptionService {
  static const String _keyAllUsers = 'subscribed_all_users';
  static const String _keyAnnouncements = 'subscribed_announcements';
  
  // all_users 토픽 구독 상태 확인
  static Future<bool> isSubscribedToAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getBool(_keyAllUsers);
      final result = storedValue ?? true; // 기본값: 구독
      print('📊 NotificationSubscriptionService.isSubscribedToAllUsers: stored=$storedValue, result=$result');
      return result;
    } catch (e) {
      print('❌ NotificationSubscriptionService.isSubscribedToAllUsers: Error - $e');
      return true; // 에러 시 기본값
    }
  }
  
  // all_users 토픽 구독/해제 토글
  static Future<bool> toggleAllUsersSubscription() async {
    try {
      final isCurrentlySubscribed = await isSubscribedToAllUsers();
      print('🔄 NotificationSubscriptionService.toggleAllUsersSubscription: current=$isCurrentlySubscribed');
      
      if (isCurrentlySubscribed) {
        print('➡️ NotificationSubscriptionService.toggleAllUsersSubscription: Unsubscribing...');
        await unsubscribeFromAllUsers();
        print('✅ NotificationSubscriptionService.toggleAllUsersSubscription: Unsubscribed, returning false');
        return false;
      } else {
        print('➡️ NotificationSubscriptionService.toggleAllUsersSubscription: Subscribing...');
        await subscribeToAllUsers();
        print('✅ NotificationSubscriptionService.toggleAllUsersSubscription: Subscribed, returning true');
        return true;
      }
    } catch (e) {
      print('❌ NotificationSubscriptionService.toggleAllUsersSubscription: Error - $e');
      final fallbackStatus = await isSubscribedToAllUsers();
      print('⚠️ NotificationSubscriptionService.toggleAllUsersSubscription: Error fallback - returning $fallbackStatus');
      return fallbackStatus;
    }
  }
  
  // all_users 토픽 구독
  static Future<void> subscribeToAllUsers() async {
    try {
      print('🔔 NotificationSubscriptionService.subscribeToAllUsers: START');
      
      // Firebase 토픽 구독 시도
      try {
        await FirebaseService().subscribeToTopic('all_users');
        print('🔥 NotificationSubscriptionService.subscribeToAllUsers: Firebase subscribe completed');
      } catch (firebaseError) {
        print('⚠️ NotificationSubscriptionService.subscribeToAllUsers: Firebase error (continuing with local state): $firebaseError');
        // 시뮬레이터에서 APNS 토큰 에러 발생 시에도 로컬 상태는 업데이트
      }
      
      // 로컬 상태 저장 (항상 실행)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAllUsers, true);
      print('💾 NotificationSubscriptionService.subscribeToAllUsers: SharedPreferences saved as true');
      
      // 저장 확인
      final saved = prefs.getBool(_keyAllUsers);
      print('✅ NotificationSubscriptionService.subscribeToAllUsers: Verification - saved value: $saved');
    } catch (e) {
      print('❌ NotificationSubscriptionService.subscribeToAllUsers: Critical error - $e');
      throw e;
    }
  }
  
  // all_users 토픽 구독 해제
  static Future<void> unsubscribeFromAllUsers() async {
    try {
      print('🔕 NotificationSubscriptionService.unsubscribeFromAllUsers: START');
      
      // Firebase 토픽 구독 해제 시도
      try {
        await FirebaseService().unsubscribeFromTopic('all_users');
        print('🔥 NotificationSubscriptionService.unsubscribeFromAllUsers: Firebase unsubscribe completed');
      } catch (firebaseError) {
        print('⚠️ NotificationSubscriptionService.unsubscribeFromAllUsers: Firebase error (continuing with local state): $firebaseError');
        // 시뮬레이터에서 APNS 토큰 에러 발생 시에도 로컬 상태는 업데이트
      }
      
      // 로컬 상태 저장 (항상 실행)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAllUsers, false);
      print('💾 NotificationSubscriptionService.unsubscribeFromAllUsers: SharedPreferences saved as false');
      
      // 저장 확인
      final saved = prefs.getBool(_keyAllUsers);
      print('✅ NotificationSubscriptionService.unsubscribeFromAllUsers: Verification - saved value: $saved');
    } catch (e) {
      print('❌ NotificationSubscriptionService.unsubscribeFromAllUsers: Critical error - $e');
      throw e;
    }
  }
  
  // announcements 토픽 구독 상태 확인
  static Future<bool> isSubscribedToAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAnnouncements) ?? true; // 기본값: 구독
    } catch (e) {
      print('NotificationSubscriptionService.isSubscribedToAnnouncements: Error - $e');
      return true;
    }
  }
  
  // announcements 토픽 구독
  static Future<void> subscribeToAnnouncements() async {
    try {
      await FirebaseService().subscribeToTopic('announcements');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnnouncements, true);
    } catch (e) {
      print('NotificationSubscriptionService.subscribeToAnnouncements: Error - $e');
      throw e;
    }
  }
  
  // announcements 토픽 구독 해제
  static Future<void> unsubscribeFromAnnouncements() async {
    try {
      await FirebaseService().unsubscribeFromTopic('announcements');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnnouncements, false);
    } catch (e) {
      print('NotificationSubscriptionService.unsubscribeFromAnnouncements: Error - $e');
      throw e;
    }
  }
  
  // 모든 구독 상태 초기화 (로그아웃 시 사용)
  static Future<void> resetAllSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAllUsers);
      await prefs.remove(_keyAnnouncements);
      print('NotificationSubscriptionService: All subscription states reset');
    } catch (e) {
      print('NotificationSubscriptionService.resetAllSubscriptions: Error - $e');
    }
  }
}