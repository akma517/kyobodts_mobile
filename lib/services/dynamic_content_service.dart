import 'package:http/http.dart' as http;
import 'dart:convert';

class DynamicContentService {
  static const Duration _timeout = Duration(seconds: 10);
  
  /// API URL에서 HTML 콘텐츠를 원본 그대로 가져오기
  static Future<String> fetchHtmlContent(String url) async {
    try {
      // URL 유효성 및 도메인 안전성 검증
      if (!isValidUrl(url)) {
        throw Exception('유효하지 않은 URL 형식입니다');
      }
      
      if (!isSafeDomain(url)) {
        throw Exception('허용되지 않은 도메인입니다');
      }
      
      print('DynamicContentService: Fetching content from $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'KyoboDTS-Mobile-App/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(_timeout);
      
      print('DynamicContentService: Response status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // 콘텐츠 크기 제한 (5MB)
        if (response.bodyBytes.length > 5 * 1024 * 1024) {
          throw Exception('콘텐츠 크기가 너무 큽니다 (5MB 초과)');
        }
        
        print('DynamicContentService: Content fetched successfully');
        return response.body; // 원본 HTML 그대로 반환
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('DynamicContentService: Error fetching content - $e');
      throw Exception('콘텐츠를 불러올 수 없습니다: $e');
    }
  }
  

  
  /// URL 유효성 검증
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// 안전한 도메인 확인 (필요시 화이트리스트 적용)
  static bool isSafeDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // 허용된 도메인 및 IP 목록
      const allowedDomains = [
        'hushush.link',
        'www.hushush.link',
        // 테스트용 도메인
        'httpbin.org',
        'jsonplaceholder.typicode.com',
      ];
      
      // 허용된 IP 주소 목록 (포트 포함)
      const allowedIPs = [
        '54.206.1.146',
      ];
      
      // 포트가 포함된 경우 호스트만 추출하여 확인
      String hostOnly = host;
      if (host.contains(':')) {
        hostOnly = host.split(':')[0];
      }
      
      // IP 주소 확인 (포트 제외)
      if (allowedIPs.contains(hostOnly)) {
        return true;
      }
      
      // 도메인 확인 (정확한 매치 또는 서브도메인 허용)
      return allowedDomains.any((domain) => 
        host == domain || host.endsWith('.$domain')
      );
    } catch (e) {
      return false;
    }
  }
}