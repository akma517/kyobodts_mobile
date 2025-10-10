import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

class PushTestHelper {
  static Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  static Map<String, dynamic> getSamplePushData() {
    return {
      'title': '교보DTS 알림',
      'body': 'Firebase 푸시 알림 테스트입니다.',
      'content_url': 'assets/html/sample_notification.html',
      'content_type': 'asset',
    };
  }

  static Map<String, dynamic> getWebPushData() {
    return {
      'title': '웹 콘텐츠 알림',
      'body': '외부 웹 페이지를 표시합니다.',
      'content_url': 'https://www.google.com',
      'content_type': 'html',
    };
  }

  static Map<String, dynamic> getPdfPushData() {
    return {
      'title': 'PDF 문서 알림',
      'body': 'PDF 문서를 표시합니다.',
      'content_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      'content_type': 'pdf',
    };
  }

  static String getCurlCommand(String fcmToken, Map<String, dynamic> data) {
    return '''
curl -X POST https://fcm.googleapis.com/fcm/send \\
  -H "Authorization: key=YOUR_SERVER_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "to": "$fcmToken",
    "notification": {
      "title": "${data['title']}",
      "body": "${data['body']}"
    },
    "data": ${_mapToJsonString(data)}
  }'
''';
  }

  static String _mapToJsonString(Map<String, dynamic> map) {
    final entries = map.entries.map((e) => '"${e.key}": "${e.value}"').join(', ');
    return '{ $entries }';
  }
}