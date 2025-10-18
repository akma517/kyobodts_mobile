import 'package:flutter/material.dart';
import 'dart:io';
import '../services/notification_subscription_service.dart';

class NotificationToggleSwitch extends StatefulWidget {
  const NotificationToggleSwitch({super.key});

  @override
  State<NotificationToggleSwitch> createState() => _NotificationToggleSwitchState();
}

class _NotificationToggleSwitchState extends State<NotificationToggleSwitch> {
  bool? _isSubscribed; // null로 초기화하여 로딩 상태 표시
  bool _isLoading = true; // 초기에는 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    print('🔄 NotificationToggleSwitch._loadSubscriptionStatus: START');
    try {
      final isSubscribed = await NotificationSubscriptionService.isSubscribedToAllUsers();
      print('📊 NotificationToggleSwitch._loadSubscriptionStatus: Loaded status = $isSubscribed');
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
          _isLoading = false;
        });
        print('✅ NotificationToggleSwitch._loadSubscriptionStatus: State updated - isSubscribed: $_isSubscribed, isLoading: $_isLoading');
      }
    } catch (e) {
      print('❌ NotificationToggleSwitch._loadSubscriptionStatus: Error - $e');
      if (mounted) {
        setState(() {
          _isSubscribed = true; // 에러 시 기본값
          _isLoading = false;
        });
        print('⚠️ NotificationToggleSwitch._loadSubscriptionStatus: Error fallback - isSubscribed: $_isSubscribed');
      }
    }
  }

  Future<void> _showConfirmDialog() async {
    print('🔘 NotificationToggleSwitch._showConfirmDialog: START - isLoading: $_isLoading, isSubscribed: $_isSubscribed');
    if (_isLoading || _isSubscribed == null) {
      print('⏸️ NotificationToggleSwitch._showConfirmDialog: BLOCKED - loading or null state');
      return;
    }

    final String title = _isSubscribed! ? '구독 취소' : '구독 신청';
    final String message = _isSubscribed! 
        ? '소식지 구독(푸시 메세지 알림)을 취소하시겠습니까?'
        : '소식지 구독(푸시 메세지 알림)을 사용하시겠습니까?';
    
    print('💬 NotificationToggleSwitch._showConfirmDialog: Showing dialog - title: $title');
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    print('🎯 NotificationToggleSwitch._showConfirmDialog: User response = $confirmed');
    if (confirmed == true) {
      await _toggleSubscription();
    } else {
      print('🚫 NotificationToggleSwitch._showConfirmDialog: User cancelled');
    }
  }

  Future<void> _toggleSubscription() async {
    print('🔄 NotificationToggleSwitch._toggleSubscription: START - current status: $_isSubscribed');
    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await NotificationSubscriptionService.toggleAllUsersSubscription();
      print('✅ NotificationToggleSwitch._toggleSubscription: Toggle completed - new status: $newStatus');
      
      if (mounted) {
        setState(() {
          _isSubscribed = newStatus;
          _isLoading = false;
        });
        print('🔄 NotificationToggleSwitch._toggleSubscription: State updated - isSubscribed: $_isSubscribed');

        _showFeedback(newStatus);
      }
    } catch (e) {
      print('❌ NotificationToggleSwitch._toggleSubscription: Error - $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showErrorFeedback();
      }
    }
  }

  void _showFeedback(bool isSubscribed) {
    if (!mounted) return;

    // 플랫폼 및 환경 감지
    final platform = Theme.of(context).platform;
    String environmentNote = '';
    
    if (platform == TargetPlatform.iOS) {
      // iOS에서는 시뮬레이터 여부를 알리기 어려우므로 일반적인 안내
      environmentNote = ' (실제 기기에서만 푸시 알림 수신 가능)';
    } else if (platform == TargetPlatform.android) {
      // Android는 에뮬레이터에서도 대부분 정상 동작
      environmentNote = '';
    }
    
    final feedbackMessage = isSubscribed 
        ? '알림이 활성화되었습니다$environmentNote'
        : '알림이 비활성화되었습니다$environmentNote';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSubscribed ? Icons.notifications_active : Icons.notifications_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feedbackMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSubscribed ? Colors.green.shade600 : Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorFeedback() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '알림 설정 변경에 실패했습니다',
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
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading || _isSubscribed == null
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : Icon(
              _isSubscribed! ? Icons.notifications_active : Icons.notifications_off,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
      onPressed: (_isLoading || _isSubscribed == null) ? null : _showConfirmDialog,
      tooltip: _isSubscribed == null 
          ? '로딩 중...'
          : _isSubscribed! ? '소식지 구독 취소' : '소식지 구독 신청',
    );
  }
}