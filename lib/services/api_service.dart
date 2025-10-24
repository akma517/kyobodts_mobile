import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/attachment.dart';
import 'session_manager.dart';

class ApiService {
  static const String baseUrl = 'https://api.kyobodts.com';
  String? _token;
  static http.Client? _httpClient;
  static final Map<String, String> _cookies = {};
  
  static Map<String, String> get cookies => _cookies;

  // 싱글톤 HTTP 클라이언트 가져오기
  static http.Client get httpClient {
    _httpClient ??= http.Client();
    return _httpClient!;
  }

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
    if (_cookies.isNotEmpty) 'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
  };
  
  // 쿠키 저장
  static void saveCookies(Map<String, String> headers) {
    final setCookie = headers['set-cookie'];
    if (setCookie != null) {
      print('ApiService: Saving cookies: $setCookie');
      final cookies = setCookie.split(',');
      for (final cookie in cookies) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          _cookies[parts[0].trim()] = parts[1].trim();
        }
      }
      print('ApiService: Current cookies: $_cookies');
    }
  }
  
  // 쿠키 가져오기
  static String getCookies() {
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  // 중앙화된 HTTP 요청 처리 (HTML 응답 자동 감지 및 재시도)
  static Future<http.Response> makeRequest(String url, {Map<String, String>? headers}) async {
    print('ApiService.makeRequest: $url');
    
    final defaultHeaders = {
      'Accept': 'application/json, text/html, */*',
      'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
      if (_cookies.isNotEmpty) 'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      ...?headers,
    };
    
    final response = await httpClient.get(Uri.parse(url), headers: defaultHeaders).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout after 30 seconds');
      },
    );
    
    print('ApiService.makeRequest: Response status ${response.statusCode}');
    print('ApiService.makeRequest: Content-Type: ${response.headers['content-type']}');
    
    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'] ?? '';
      final trimmedBody = response.body.trim();
      
      // HTML 응답 감지: Content-Type이 text/html이거나 본문에 HTML 태그가 있는 경우
      bool isHtmlResponse = contentType.toLowerCase().contains('text/html') || 
                           trimmedBody.toLowerCase().contains('<html>') ||
                           trimmedBody.toLowerCase().contains('<!doctype html>');
      
      // JSON이 아닌 경우에만 HTML 감지 처리
      if (!trimmedBody.startsWith('{') && !trimmedBody.startsWith('[') && isHtmlResponse) {
        print('ApiService.makeRequest: HTML response detected (Content-Type: $contentType)');
        final sessionHandled = await SessionManager().handleHtmlResponse();
        
        if (sessionHandled) {
          print('ApiService.makeRequest: Session handled, retrying request');
          return await makeRequest(url, headers: headers);
        }
      }
    }
    
    return response;
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  // 게시글 목록 조회 (교보DTS API)
  Future<List<Post>> getPosts({String? section, int page = 1, int limit = 10}) async {
    // 섹션이 지정된 경우 섹션별 API 사용
    if (section != null && section.isNotEmpty) {
      return getSectionPosts(section, page: page, limit: limit);
    }
    
    try {
      final response = await makeRequest('https://km.kyobodts.co.kr/bbs/bbs.do?method=mainBbsList&coid=156&ctid=158');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseApiResponse(data, section ?? '', limit * 2); // 더 많이 가져와서 필터링
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  // 최근 게시글 조회 (교보DTS API)
  Future<List<Post>> getRecentPosts(String section, {int limit = 5}) async {
    try {
      final response = await makeRequest('https://km.kyobodts.co.kr/bbs/bbs.do?method=mainBbsList&coid=156&ctid=158');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseApiResponse(data, section, limit);
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }
  
  List<Post> _parseApiResponse(Map<String, dynamic> data, String section, int limit) {
    List<Post> posts = [];
    
    // 섹션별 매핑
    String? listKey;
    switch (section) {
      case '공지사항':
        listKey = 'bbs11List';
        break;
      case '회사소식':
        listKey = 'bbs01List';
        break;
      case '사우소식·자유게시판':
        listKey = 'bbs02List';
        break;
      case '디지털에듀':
        listKey = 'bbs07List';
        break;
    }
    
    if (listKey != null && data[listKey] != null) {
      final List<dynamic> items = data[listKey];
      posts = items.map((item) => Post.fromApiJson(item)).toList();
      
      // 날짜 내림차순 정렬
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // limit 적용
      if (posts.length > limit) {
        posts = posts.take(limit).toList();
      }
    }
    
    return posts;
  }
  
  // 전체 API 응답을 섹션별로 파싱
  Map<String, List<Post>> parseAllSections(Map<String, dynamic> data) {
    Map<String, List<Post>> sectionPosts = {};
    
    // 모든 리스트 키와 해당 섹션 매핑
    final listMappings = {
      'bbs11List': '공지사항',
      'bbs01List': '회사소식', 
      'bbs02List': '사우소식+자유게시판', // 임시 키
      'bbs07List': '디지털에듀',
    };
    
    listMappings.forEach((listKey, sectionName) {
      if (data[listKey] != null) {
        final List<dynamic> items = data[listKey];
        List<Post> posts = items.map((item) {
          final post = Post.fromApiJson(item);
          // ctid 기반으로 섹션 결정
          String section = _getSectionByCtid(post.ctid);
          
          // 사우소식·자유게시판의 경우 실제 ctid 값 확인 및 수정
          int actualCtid = post.ctid;
          if (listKey == 'bbs02List') {
            // bbs02List에서 오는 게시글들의 ctid를 실제 값으로 매핑
            // API 응답에서 ctid가 잘못 설정되어 있을 수 있으므로 원본 데이터 확인
            if (item['ctid'] != null) {
              actualCtid = int.tryParse(item['ctid'].toString()) ?? post.ctid;
            }
            section = _getSectionByCtid(actualCtid);
          }
          
          return Post(
            id: post.id,
            title: post.title,
            content: post.content,
            author: post.author,
            createdAt: post.createdAt,
            viewCount: post.viewCount,
            commentCount: post.commentCount,
            hasAttachment: post.hasAttachment,
            section: section,
            attachments: post.attachments,
            ctid: actualCtid,
            docNumber: post.docNumber,
            fileCnt: post.fileCnt,
            bbsId: post.bbsId,
          );
        }).toList();
        
        // 날짜 내림차순 정렬
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // 섹션별로 그룹화
        for (var post in posts) {
          if (!sectionPosts.containsKey(post.section)) {
            sectionPosts[post.section] = [];
          }
          sectionPosts[post.section]!.add(post);
        }
      }
    });
    
    return sectionPosts;
  }
  
  String _getSectionByCtid(int ctid) {
    switch (ctid) {
      case 321:
        return '공지사항';
      case 172:
        return '회사소식';
      case 164:
      case 20:
        return '사우소식·자유게시판';
      case 313:
        return '디지털에듀';
      default:
        return '기타';
    }
  }

  int _getCtidBySection(String section) {
    switch (section) {
      case '공지사항':
        return 321;
      case '회사소식':
        return 172;
      case '사우소식·자유게시판':
        return 164; // 사우소식 CTID 사용
      case '디지털에듀':
        return 313;
      default:
        return 158; // 기본값
    }
  }

  // 섹션별 게시글 목록 조회
  Future<List<Post>> getSectionPosts(String section, {int page = 1, int limit = 20}) async {
    print('ApiService.getSectionPosts: START - section: $section, page: $page, limit: $limit');
    try {
      final ctid = _getCtidBySection(section);
      print('ApiService.getSectionPosts: CTID mapped - section: $section -> ctid: $ctid');
      print('ApiService.getSectionPosts: Current cookies: $_cookies');
      
      final url = 'https://km.kyobodts.co.kr/bbs/bbsFinder.do?method=list&coid=156&ctid=$ctid';
      print('ApiService.getSectionPosts: Calling API - $url');
      
      final response = await makeRequest(url);
      
      print('ApiService.getSectionPosts: Response status: ${response.statusCode}');
      print('ApiService.getSectionPosts: Response headers: ${response.headers}');
      print('ApiService.getSectionPosts: Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
        print('ApiService.getSectionPosts: Response body preview: $bodyPreview');
        
        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            print('ApiService.getSectionPosts: JSON parsing successful');
            print('ApiService.getSectionPosts: Response keys: ${data.keys.toList()}');
            
            final posts = _parseSectionApiResponse(data, section, limit);
            print('ApiService.getSectionPosts: Parsed ${posts.length} posts');
            return posts;
          } catch (e) {
            print('ApiService.getSectionPosts: JSON parsing failed - $e');
            return [];
          }
        } else {
          print('ApiService.getSectionPosts: Response is not JSON format');
          return [];
        }
      } else {
        print('ApiService.getSectionPosts: HTTP error ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('ApiService.getSectionPosts: Exception - $e');
      return [];
    }
  }

  List<Post> _parseSectionApiResponse(Map<String, dynamic> data, String section, int limit) {
    print('ApiService._parseSectionApiResponse: START - section: $section, limit: $limit');
    List<Post> posts = [];
    
    if (data['list'] != null) {
      final List<dynamic> items = data['list'];
      print('ApiService._parseSectionApiResponse: Found ${items.length} items in list');
      
      try {
        posts = items.map((item) {
          final post = Post.fromApiJson(item);
          print('ApiService._parseSectionApiResponse: Parsed post - title: ${post.title}, author: ${post.author}, ctid: ${post.ctid}');
          return post;
        }).toList();
        
        print('ApiService._parseSectionApiResponse: Successfully parsed ${posts.length} posts');
        
        // 날짜 내림차순 정렬
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('ApiService._parseSectionApiResponse: Posts sorted by date');
        
        // limit 적용
        if (posts.length > limit) {
          posts = posts.take(limit).toList();
          print('ApiService._parseSectionApiResponse: Limited to $limit posts');
        }
      } catch (e) {
        print('ApiService._parseSectionApiResponse: Error parsing posts - $e');
        return [];
      }
    } else {
      print('ApiService._parseSectionApiResponse: No list found in response data');
      print('ApiService._parseSectionApiResponse: Available keys: ${data.keys.toList()}');
    }
    
    print('ApiService._parseSectionApiResponse: Returning ${posts.length} posts');
    return posts;
  }

  // 게시글 상세 조회
  Future<Post?> getPost(String postId) async {
    try {
      final response = await get('/posts/$postId');
      return _parsePost(response['data']);
    } catch (e) {
      return null;
    }
  }

  // 댓글 목록 조회 (교보DTS API)
  Future<List<Comment>> getComments(String postId, String bbsId) async {
    print('ApiService.getComments: START - postId: $postId, bbsId: $bbsId');
    try {
      final url = 'https://km.kyobodts.co.kr/bbs/bbsDocReply.do?method=listView&bbsId=$bbsId&docNumber=$postId';
      print('ApiService.getComments: Calling API - $url');
      print('ApiService.getComments: Current cookies: $_cookies');
      
      final response = await makeRequest(url);
      
      print('ApiService.getComments: Response status: ${response.statusCode}');
      print('ApiService.getComments: Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
        print('ApiService.getComments: Response body preview: $bodyPreview');
        
        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            print('ApiService.getComments: JSON parsing successful');
            print('ApiService.getComments: Response keys: ${data.keys.toList()}');
            
            if (data['replyList'] != null) {
              final List<dynamic> replyList = data['replyList'];
              print('ApiService.getComments: Found ${replyList.length} comments');
              
              final comments = replyList.map((json) {
                print('ApiService.getComments: Parsing comment - author: ${json['replyUserName']}, userId: ${json['replyUserId']}, content: ${json['reText']}');
                return Comment.fromApiJson(json);
              }).toList();
              
              print('ApiService.getComments: Successfully parsed ${comments.length} comments');
              return comments;
            } else {
              print('ApiService.getComments: No replyList found in response');
            }
          } catch (jsonError) {
            print('ApiService.getComments: JSON parsing failed - $jsonError');
            return [];
          }
        } else {
          print('ApiService.getComments: Response is not JSON format - HTML response detected');
          return [];
        }
      } else {
        print('ApiService.getComments: HTTP error ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('ApiService.getComments: Exception - $e');
      return [];
    }
  }

  // 댓글 수정
  Future<void> updateComment(String commentId, String content) async {
    await post('/comments/$commentId', {'content': content});
  }

  // 댓글 삭제
  Future<void> deleteComment(String commentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Comment delete failed: ${response.statusCode}');
    }
  }

  // 댓글 추가
  Future<Comment> addComment(String postId, String content) async {
    final response = await post('/posts/$postId/comments', {'content': content});
    final commentJson = response['data'];
    
    return Comment(
      id: commentJson['id'],
      postId: commentJson['postId'],
      author: commentJson['author'],
      content: commentJson['content'],
      createdAt: DateTime.parse(commentJson['createdAt']),
      bbsId: commentJson['bbsId'] ?? '',
      docNumber: commentJson['docNumber'] ?? 0,
      userId: commentJson['userId'] ?? '',
      seqno: commentJson['seqno'] ?? 0,
    );
  }

  // 전체 섹션 데이터 가져오기
  Future<Map<String, List<Post>>> getAllSectionPosts({int limit = 5}) async {
    print('ApiService.getAllSectionPosts: START');
    try {
      print('ApiService.getAllSectionPosts: Calling API...');
      print('ApiService.getAllSectionPosts: Current cookies: $_cookies');
      
      final response = await makeRequest('https://km.kyobodts.co.kr/bbs/bbs.do?method=mainBbsList&coid=156&ctid=158');
      
      print('ApiService.getAllSectionPosts: Request sent with cookies: ${_cookies.entries.map((e) => '${e.key}=${e.value}').join('; ')}');
      
      print('ApiService.getAllSectionPosts: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('ApiService.getAllSectionPosts: Parsing response...');
        print('ApiService.getAllSectionPosts: Response body length: ${response.body.length}');
        print('ApiService.getAllSectionPosts: Response headers: ${response.headers}');
        final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
        print('ApiService.getAllSectionPosts: Response body preview: $bodyPreview');
        
        // 첫 번째 문자 확인
        if (response.body.isNotEmpty) {
          print('ApiService.getAllSectionPosts: First character code: ${response.body.codeUnitAt(0)}');
          print('ApiService.getAllSectionPosts: First character: "${response.body[0]}"');
        }
        
        // JSON 여부 확인
        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            print('ApiService.getAllSectionPosts: JSON parsing successful');
            print('ApiService.getAllSectionPosts: Response keys: ${data.keys.toList()}');
            
            final allSectionPosts = parseAllSections(data);
            print('ApiService.getAllSectionPosts: Parsed ${allSectionPosts.length} sections');
            
            // 각 섹션별로 limit 적용
            Map<String, List<Post>> limitedPosts = {};
            allSectionPosts.forEach((section, posts) {
              limitedPosts[section] = posts.take(limit).toList();
              print('ApiService.getAllSectionPosts: Section $section limited to ${limitedPosts[section]!.length} posts');
            });
            
            return limitedPosts;
          } catch (e) {
            print('ApiService.getAllSectionPosts: JSON parsing failed - $e');
            return {};
          }
        } else {
          print('ApiService.getAllSectionPosts: Response is not JSON format');
          print('ApiService.getAllSectionPosts: Content-Type: ${response.headers['content-type']}');
          return {};
        }
      } else {
        print('ApiService.getAllSectionPosts: HTTP error ${response.statusCode}');
      }
      return {};
    } catch (e) {
      print('ApiService.getAllSectionPosts: Exception - $e');
      return {};
    }
  }

  // API 테스트 메서드
  static Future<void> testApiCall() async {
    print('=== API TEST START ===');
    print('Current cookies: $_cookies');
    try {
      final response = await httpClient.get(
        Uri.parse('https://km.kyobodts.co.kr/bbs/bbs.do?method=mainBbsList&coid=156&ctid=158'),
        headers: {
          'Accept': 'application/json, text/html, */*',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          if (_cookies.isNotEmpty) 'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        },
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.body.length}');
      
      if (response.body.isNotEmpty) {
        print('First 10 characters: "${response.body.substring(0, response.body.length > 10 ? 10 : response.body.length)}"');
        print('First character ASCII: ${response.body.codeUnitAt(0)}');
        
        final preview = response.body.length > 1000 ? response.body.substring(0, 1000) : response.body;
        print('Response Preview (first 1000 chars):\n$preview');
        
        // JSON 여부 확인
        final trimmed = response.body.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          print('Response appears to be JSON format');
          try {
            final data = jsonDecode(response.body);
            print('JSON parsing successful');
            if (data is Map) {
              print('JSON keys: ${data.keys.toList()}');
            }
          } catch (e) {
            print('JSON parsing failed: $e');
          }
        } else {
          print('Response is NOT JSON format');
          if (response.body.toLowerCase().contains('<html>')) {
            print('Response contains HTML');
          }
          if (response.body.toLowerCase().contains('login')) {
            print('Response contains "login" - might be login page');
          }
        }
      }
    } catch (e) {
      print('API Test Error: $e');
    }
    print('=== API TEST END ===');
  }

  // Post JSON 파싱
  Post _parsePost(Map<String, dynamic> json) {
    List<Attachment> attachments = [];
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((attachmentJson) => Attachment.fromJson(attachmentJson))
          .toList();
    }

    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      viewCount: json['viewCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      hasAttachment: json['hasAttachment'] ?? false,
      section: json['section'],
      attachments: attachments,
      ctid: json['ctid'] ?? 0,
      docNumber: json['docNumber'] ?? 0,
      fileCnt: json['fileCnt'] ?? 0,
      bbsId: json['bbsId'] ?? '',
    );
  }
}