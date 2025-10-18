import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inapp_notification.dart';

class InAppNotificationService {
  static const String _keyNotifications = 'inapp_notifications';
  static const int _maxNotifications = 100; // 최대 저장 개수
  
  static List<InAppNotification> _notifications = [];
  static bool _isInitialized = false;

  /// 서비스 초기화 (앱 시작 시 호출)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadNotificationsFromStorage();
      _isInitialized = true;
      print('InAppNotificationService: Initialized with ${_notifications.length} notifications');
    } catch (e) {
      print('InAppNotificationService: Initialization error - $e');
      _notifications = [];
      _isInitialized = true;
    }
  }

  /// 새 알림 추가
  static Future<void> addNotification({
    required String title,
    required String body,
    String? contentUrl,
    String? contentType,
    Map<String, dynamic>? customData,
  }) async {
    await initialize();
    
    try {
      final notification = InAppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        contentUrl: contentUrl,
        contentType: contentType,
        timestamp: DateTime.now(),
        customData: customData,
      );

      // 리스트 앞쪽에 추가 (최신 순)
      _notifications.insert(0, notification);

      // 최대 개수 제한
      if (_notifications.length > _maxNotifications) {
        _notifications = _notifications.take(_maxNotifications).toList();
      }

      await _saveNotificationsToStorage();
      print('InAppNotificationService: Added notification - ${notification.title}');
    } catch (e) {
      print('InAppNotificationService: Error adding notification - $e');
    }
  }

  /// 모든 알림 조회
  static Future<List<InAppNotification>> getAllNotifications() async {
    await initialize();
    return List.from(_notifications);
  }

  /// 읽지 않은 알림 조회
  static Future<List<InAppNotification>> getUnreadNotifications() async {
    await initialize();
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// 읽지 않은 알림 개수
  static Future<int> getUnreadCount() async {
    await initialize();
    return _notifications.where((n) => !n.isRead).length;
  }

  /// 특정 알림을 읽음으로 표시
  static Future<void> markAsRead(String notificationId) async {
    await initialize();
    
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].markAsRead();
        await _saveNotificationsToStorage();
        print('InAppNotificationService: Marked as read - $notificationId');
      }
    } catch (e) {
      print('InAppNotificationService: Error marking as read - $e');
    }
  }

  /// 모든 알림을 읽음으로 표시
  static Future<void> markAllAsRead() async {
    await initialize();
    
    try {
      for (var notification in _notifications) {
        notification.markAsRead();
      }
      await _saveNotificationsToStorage();
      print('InAppNotificationService: Marked all as read');
    } catch (e) {
      print('InAppNotificationService: Error marking all as read - $e');
    }
  }

  /// 특정 알림 삭제
  static Future<void> deleteNotification(String notificationId) async {
    await initialize();
    
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotificationsToStorage();
      print('InAppNotificationService: Deleted notification - $notificationId');
    } catch (e) {
      print('InAppNotificationService: Error deleting notification - $e');
    }
  }

  /// 모든 알림 삭제
  static Future<void> clearAllNotifications() async {
    await initialize();
    
    try {
      _notifications.clear();
      await _saveNotificationsToStorage();
      print('InAppNotificationService: Cleared all notifications');
    } catch (e) {
      print('InAppNotificationService: Error clearing notifications - $e');
    }
  }

  /// 오래된 알림 정리 (30일 이상)
  static Future<void> cleanupOldNotifications() async {
    await initialize();
    
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final initialCount = _notifications.length;
      
      _notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
      
      if (_notifications.length != initialCount) {
        await _saveNotificationsToStorage();
        print('InAppNotificationService: Cleaned up ${initialCount - _notifications.length} old notifications');
      }
    } catch (e) {
      print('InAppNotificationService: Error cleaning up notifications - $e');
    }
  }

  /// 권한 차단 사용자를 위한 푸시 메시지 처리
  static Future<void> handleBlockedPushMessage(Map<String, dynamic> data) async {
    try {
      await addNotification(
        title: data['title'] ?? '알림',
        body: data['body'] ?? '',
        contentUrl: data['content_url'],
        contentType: data['content_type'],
        customData: data,
      );
      print('InAppNotificationService: Handled blocked push message');
    } catch (e) {
      print('InAppNotificationService: Error handling blocked push - $e');
    }
  }

  /// SharedPreferences에서 알림 로드
  static Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_keyNotifications) ?? [];
      
      _notifications = notificationsJson
          .map((json) => InAppNotification.fromMap(jsonDecode(json)))
          .toList();
      
      // 시간순 정렬 (최신 순)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('InAppNotificationService: Error loading from storage - $e');
      _notifications = [];
    }
  }

  /// SharedPreferences에 알림 저장
  static Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toMap()))
          .toList();
      
      await prefs.setStringList(_keyNotifications, notificationsJson);
    } catch (e) {
      print('InAppNotificationService: Error saving to storage - $e');
    }
  }

  /// 서비스 상태 확인
  static bool get isInitialized => _isInitialized;

  /// 현재 알림 개수
  static int get notificationCount => _notifications.length;
}