import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_list_item.dart';
import 'api_service.dart';
import 'session_manager.dart';

class PostListApiService {
  // ApiService의 쿠키를 사용
  Map<String, String> get _cookies {
    return ApiService.cookies;
  }

  int _getCtidBySection(String section) {
    switch (section) {
      case '공지사항':
        return 321;
      case '회사소식':
        return 172;
      case '사우소식·자유게시판':
        return 164;
      case '디지털에듀':
        return 313;
      default:
        return 158;
    }
  }

  Future<List<PostListItem>> getSectionPosts(String section, {int page = 1, int limit = 20}) async {
    print('=== PostListApiService.getSectionPosts START ===');
    print('PostListApiService.getSectionPosts: section = "$section"');
    print('PostListApiService.getSectionPosts: page = $page, limit = $limit');
    
    final startTime = DateTime.now();
    
    try {
      final ctid = _getCtidBySection(section);
      print('PostListApiService.getSectionPosts: CTID mapped - section: "$section" -> ctid: $ctid');
      
      final url = 'https://km.kyobodts.co.kr/bbs/bbsFinder.do?method=list&coid=156&ctid=$ctid';
      print('PostListApiService.getSectionPosts: API URL = $url');
      print('PostListApiService.getSectionPosts: Current cookies count = ${_cookies.length}');
      
      if (_cookies.isNotEmpty) {
        print('PostListApiService.getSectionPosts: Cookie keys = ${_cookies.keys.toList()}');
      } else {
        print('PostListApiService.getSectionPosts: No cookies available');
      }
      
      final response = await ApiService.httpClient.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/html, */*',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          if (_cookies.isNotEmpty) 'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        },
      );
      
      final requestTime = DateTime.now().difference(startTime).inMilliseconds;
      print('PostListApiService.getSectionPosts: HTTP request took ${requestTime}ms');
      print('PostListApiService.getSectionPosts: Response status = ${response.statusCode}');
      print('PostListApiService.getSectionPosts: Response headers = ${response.headers}');
      print('PostListApiService.getSectionPosts: Response body length = ${response.body.length}');
      
      if (response.statusCode == 200) {
        final bodyPreview = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('PostListApiService.getSectionPosts: Response body preview (200 chars): $bodyPreview');
        
        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          print('PostListApiService.getSectionPosts: Response is JSON format');
          
          try {
            final data = jsonDecode(response.body);
            print('PostListApiService.getSectionPosts: JSON parsing successful');
            print('PostListApiService.getSectionPosts: JSON keys = ${data.keys.toList()}');
            
            print('PostListApiService.getSectionPosts: Attempting to parse API response...');
            print('PostListApiService.getSectionPosts: page value = ${data['page']} (type: ${data['page'].runtimeType})');
            print('PostListApiService.getSectionPosts: rows value = ${data['rows']?.runtimeType} (length: ${data['rows']?.length})');
            print('PostListApiService.getSectionPosts: total = ${data['total']}, records = ${data['records']}');
            
            final apiResponse = PostListApiResponse.fromJson(data);
            print('PostListApiService.getSectionPosts: API response parsed - page: ${apiResponse.page}, rows: ${apiResponse.rows.length}, total: ${apiResponse.total}, records: ${apiResponse.records}');
            
            var items = apiResponse.rows;
            print('PostListApiService.getSectionPosts: Before sorting - ${items.length} items');
            
            // 날짜별 정렬 전 로깅
            for (int i = 0; i < items.length && i < 3; i++) {
              print('PostListApiService.getSectionPosts: Item $i - docNumber: ${items[i].docNumber}, subject: "${items[i].docSubject}", date: ${items[i].docRegDate}');
            }
            
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            print('PostListApiService.getSectionPosts: After sorting - ${items.length} items');
            
            if (items.length > limit) {
              items = items.take(limit).toList();
              print('PostListApiService.getSectionPosts: Limited to $limit items');
            }
            
            final totalTime = DateTime.now().difference(startTime).inMilliseconds;
            print('PostListApiService.getSectionPosts: Total processing time = ${totalTime}ms');
            print('PostListApiService.getSectionPosts: Returning ${items.length} items');
            print('=== PostListApiService.getSectionPosts SUCCESS ===');
            
            return items;
          } catch (jsonError) {
            print('PostListApiService.getSectionPosts: JSON parsing failed - $jsonError');
            print('=== PostListApiService.getSectionPosts JSON ERROR ===');
            return [];
          }
        } else {
          print('PostListApiService.getSectionPosts: Response is NOT JSON format');
          if (response.body.toLowerCase().contains('<html>')) {
            print('PostListApiService.getSectionPosts: Response contains HTML - handling session');
            final sessionHandled = await SessionManager().handleHtmlResponse();
            
            if (sessionHandled) {
              print('PostListApiService.getSectionPosts: Session handled, retrying API call');
              return await getSectionPosts(section, page: page, limit: limit);
            }
          }
          print('=== PostListApiService.getSectionPosts NOT JSON ===');
          return [];
        }
      } else {
        print('PostListApiService.getSectionPosts: HTTP error - status: ${response.statusCode}');
        print('=== PostListApiService.getSectionPosts HTTP ERROR ===');
        return [];
      }
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      print('PostListApiService.getSectionPosts: Exception after ${totalTime}ms - $e');
      print('PostListApiService.getSectionPosts: Exception type: ${e.runtimeType}');
      print('=== PostListApiService.getSectionPosts EXCEPTION ===');
      return [];
    }
  }
}