import 'package:http/http.dart' as http;
import 'dart:convert';

class DynamicContentService {
  static const Duration _timeout = Duration(seconds: 10);
  
  /// API URL에서 HTML 콘텐츠를 가져와서 모바일에 최적화
  static Future<String> fetchAndOptimizeHtml(String url) async {
    try {
      print('DynamicContentService: Fetching content from $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'KyoboDTS-Mobile-App/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(_timeout);
      
      print('DynamicContentService: Response status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final optimizedHtml = _optimizeHtmlForMobile(response.body);
        print('DynamicContentService: Content optimized successfully');
        return optimizedHtml;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('DynamicContentService: Error fetching content - $e');
      throw Exception('콘텐츠를 불러올 수 없습니다: $e');
    }
  }
  
  /// HTML을 모바일에 최적화
  static String _optimizeHtmlForMobile(String html) {
    try {
      // 모바일 최적화 CSS 스타일
      const mobileCSS = '''
        <style>
          /* 기본 모바일 최적화 */
          * {
            box-sizing: border-box;
            -webkit-text-size-adjust: 100%;
          }
          
          body {
            margin: 0;
            padding: 16px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: #333;
            background-color: #fff;
            word-wrap: break-word;
            overflow-wrap: break-word;
          }
          
          /* 이미지 최적화 */
          img {
            max-width: 100% !important;
            height: auto !important;
            display: block;
            margin: 8px 0;
          }
          
          /* 테이블 최적화 */
          table {
            width: 100% !important;
            border-collapse: collapse;
            font-size: 14px;
            overflow-x: auto;
            display: block;
            white-space: nowrap;
          }
          
          table thead {
            display: table-header-group;
          }
          
          table tbody {
            display: table-row-group;
          }
          
          table tr {
            display: table-row;
          }
          
          table td, table th {
            display: table-cell;
            padding: 8px;
            border: 1px solid #ddd;
            text-align: left;
            vertical-align: top;
          }
          
          /* 링크 스타일 */
          a {
            color: #007AFF;
            text-decoration: none;
            word-break: break-all;
          }
          
          a:hover {
            text-decoration: underline;
          }
          
          /* 제목 스타일 */
          h1, h2, h3, h4, h5, h6 {
            margin: 16px 0 8px 0;
            font-weight: bold;
            line-height: 1.3;
          }
          
          h1 { font-size: 24px; }
          h2 { font-size: 20px; }
          h3 { font-size: 18px; }
          h4 { font-size: 16px; }
          h5 { font-size: 14px; }
          h6 { font-size: 12px; }
          
          /* 문단 스타일 */
          p {
            margin: 8px 0;
            text-align: justify;
          }
          
          /* 리스트 스타일 */
          ul, ol {
            margin: 8px 0;
            padding-left: 20px;
          }
          
          li {
            margin: 4px 0;
          }
          
          /* 코드 블록 */
          pre, code {
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 14px;
            background-color: #f5f5f5;
            padding: 4px 8px;
            border-radius: 4px;
            overflow-x: auto;
          }
          
          pre {
            padding: 12px;
            margin: 8px 0;
            white-space: pre-wrap;
            word-wrap: break-word;
          }
          
          /* 인용문 */
          blockquote {
            margin: 8px 0;
            padding: 8px 16px;
            border-left: 4px solid #007AFF;
            background-color: #f9f9f9;
            font-style: italic;
          }
          
          /* 폼 요소 */
          input, textarea, select, button {
            font-size: 16px;
            padding: 8px;
            margin: 4px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
            max-width: 100%;
          }
          
          /* 반응형 미디어 쿼리 */
          @media (max-width: 480px) {
            body {
              padding: 12px;
              font-size: 14px;
            }
            
            table {
              font-size: 12px;
            }
            
            h1 { font-size: 20px; }
            h2 { font-size: 18px; }
            h3 { font-size: 16px; }
          }
          
          /* 다크 모드 지원 */
          @media (prefers-color-scheme: dark) {
            body {
              background-color: #1a1a1a;
              color: #e0e0e0;
            }
            
            a {
              color: #4A90E2;
            }
            
            table td, table th {
              border-color: #444;
            }
            
            pre, code {
              background-color: #2a2a2a;
              color: #e0e0e0;
            }
            
            blockquote {
              background-color: #2a2a2a;
              border-left-color: #4A90E2;
            }
          }
        </style>
      ''';
      
      // HTML 구조 확인 및 CSS 주입
      String optimizedHtml = html;
      
      // <head> 태그가 있으면 그 안에 CSS 추가
      if (optimizedHtml.toLowerCase().contains('<head>')) {
        optimizedHtml = optimizedHtml.replaceFirst(
          RegExp(r'<head>', caseSensitive: false),
          '<head>$mobileCSS'
        );
      } 
      // <html> 태그가 있으면 그 다음에 CSS 추가
      else if (optimizedHtml.toLowerCase().contains('<html>')) {
        final htmlMatch = RegExp(r'<html[^>]*>', caseSensitive: false).firstMatch(optimizedHtml);
        if (htmlMatch != null) {
          final htmlTag = htmlMatch.group(0)!;
          optimizedHtml = optimizedHtml.replaceFirst(htmlTag, '$htmlTag<head>$mobileCSS</head>');
        }
      }
      // 그 외의 경우 HTML 앞에 CSS 추가
      else {
        optimizedHtml = '<head>$mobileCSS</head>$optimizedHtml';
      }
      
      // 뷰포트 메타 태그 추가 (없는 경우)
      if (!optimizedHtml.toLowerCase().contains('viewport')) {
        const viewportMeta = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">';
        
        if (optimizedHtml.toLowerCase().contains('<head>')) {
          optimizedHtml = optimizedHtml.replaceFirst(
            RegExp(r'<head>', caseSensitive: false),
            '<head>$viewportMeta'
          );
        } else {
          optimizedHtml = '$viewportMeta$optimizedHtml';
        }
      }
      
      return optimizedHtml;
    } catch (e) {
      print('DynamicContentService: Error optimizing HTML - $e');
      // 최적화 실패 시 원본 HTML 반환
      return html;
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
      
      // 허용된 도메인 목록 (필요시 확장)
      const allowedDomains = [
        'kyobodts.com',
        'www.kyobodts.com',
        'api.kyobodts.com',
        'internal.kyobodts.com',
        // 테스트용 도메인들
        'www.google.com',
        'example.com',
        'httpbin.org',
      ];
      
      // 정확한 도메인 매치 또는 서브도메인 허용
      return allowedDomains.any((domain) => 
        host == domain || host.endsWith('.$domain')
      );
    } catch (e) {
      return false;
    }
  }
}