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
        return 164; // 기본적으로 사우소식 ctid 사용
      case '사우소식':
        return 164;
      case '자유게시판':
        return 20;
      case '디지털에듀':
        return 313;
      default:
        return 158;
    }
  }

  Future<List<PostListItem>> getSectionPosts(String section, {int page = 1, int limit = 10, String searchCondition = '', String searchString = ''}) async {
    print('=== PostListApiService.getSectionPosts START ===');
    print('PostListApiService.getSectionPosts: section = "$section"');
    print('PostListApiService.getSectionPosts: page = $page, limit = $limit');
    
    final startTime = DateTime.now();
    
    try {
      final ctid = _getCtidBySection(section);
      print('PostListApiService.getSectionPosts: CTID mapped - section: "$section" -> ctid: $ctid');
      
      String url = 'https://km.kyobodts.co.kr/bbs/bbsFinder.do?method=list&coid=156&ctid=$ctid&page=$page&rows=$limit';
      
      if (searchString.isNotEmpty && searchCondition.isNotEmpty) {
        url += '&searchCondition=$searchCondition&searchString=${Uri.encodeComponent(searchString)}';
      }
      
      print('PostListApiService.getSectionPosts: searchCondition = $searchCondition, searchString = $searchString');
      print('PostListApiService.getSectionPosts: API URL = $url');
      print('PostListApiService.getSectionPosts: Current cookies count = ${_cookies.length}');
      
      if (_cookies.isNotEmpty) {
        print('PostListApiService.getSectionPosts: Cookie keys = ${_cookies.keys.toList()}');
      } else {
        print('PostListApiService.getSectionPosts: No cookies available');
      }
      
      final response = await ApiService.makeRequest(url);
      
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
            
            // 날짜별 정렬 전 로깅 및 실제 API 데이터 확인
            for (int i = 0; i < items.length && i < 3; i++) {
              print('PostListApiService.getSectionPosts: Item $i - docNumber: ${items[i].docNumber}, subject: "${items[i].docSubject}", RAW docRegdate: "${items[i].docRegdate}", parsed createdAt: ${items[i].createdAt}');
            }
            
            // 원본 JSON 데이터에서 docRegdate 확인
            if (data['rows'] != null && (data['rows'] as List).isNotEmpty) {
              for (int i = 0; i < (data['rows'] as List).length && i < 3; i++) {
                final rawItem = data['rows'][i];
                print('PostListApiService.getSectionPosts: RAW JSON Item $i - docRegdate: "${rawItem['docRegdate']}"');
              }
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