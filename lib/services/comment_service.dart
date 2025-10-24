import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import 'api_service.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class CommentService {
  static const String baseUrl = 'https://km.kyobodts.co.kr';
  final AuthService _authService = AuthService();

  // 댓글 작성
  Future<Comment?> createComment({
    required String bbsId,
    required int docNumber,
    required String content,
  }) async {
    print('CommentService.createComment: START');
    print('CommentService.createComment: bbsId=$bbsId, docNumber=$docNumber, content length=${content.length}');
    
    try {
      final url = '$baseUrl/bbs/bbsDocReply.do?method=create';
      final now = DateTime.now();
      final reRegdate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      final body = {
        'bbsId': bbsId,
        'docNumber': docNumber.toString(),
        'reRegdate': reRegdate,
        'reText': content,
      };
      
      print('CommentService.createComment: Request body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json, text/html, */*',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          if (ApiService.cookies.isNotEmpty) 
            'Cookie': ApiService.cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        },
        body: body.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );
      
      print('CommentService.createComment: Response status: ${response.statusCode}');
      print('CommentService.createComment: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final trimmedBody = response.body.trim();
        
        // HTML 응답 감지 (세션 만료)
        if (response.body.toLowerCase().contains('<html>') || 
            response.body.toLowerCase().contains('<!doctype html>')) {
          print('CommentService.createComment: HTML response detected - session may be expired');
          await SessionManager().handleHtmlResponse();
          return null;
        }
        
        // JSON 응답 처리
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            // JSON에서 오류 메시지 확인
            if (data['error'] != null || data['message']?.toString().toLowerCase().contains('error') == true) {
              print('CommentService.createComment: API returned error: ${data['error'] ?? data['message']}');
              return null;
            }
          } catch (e) {
            print('CommentService.createComment: JSON parsing failed but continuing: $e');
          }
        }
        
        // HTTP 200이고 HTML이 아니면 성공으로 간주
        print('CommentService.createComment: Treating as success (HTTP 200, non-HTML)');
        final currentUser = _authService.currentUser;
        return Comment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          postId: docNumber.toString(),
          author: currentUser?.name ?? 'Unknown User',
          content: content,
          createdAt: now,
          bbsId: bbsId,
          docNumber: docNumber,
          userId: currentUser?.id ?? 'unknown',
          seqno: 0,
        );
      }
      
      return null;
    } catch (e) {
      print('CommentService.createComment: Exception - $e');
      return null;
    }
  }

  // 댓글 수정
  Future<bool> updateComment({
    required String bbsId,
    required int docNumber,
    required int reSeqno,
    required String content,
    required String userId,
  }) async {
    print('CommentService.updateComment: START');
    print('CommentService.updateComment: bbsId=$bbsId, docNumber=$docNumber, reSeqno=$reSeqno, userId=$userId');
    
    try {
      final url = '$baseUrl/bbs/bbsDocReply.do?method=update&userId=$userId';
      final now = DateTime.now();
      final reRegdate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      final body = {
        'bbsId': bbsId,
        'docNumber': docNumber.toString(),
        'reRegdate': reRegdate,
        'reSeqno': reSeqno.toString(),
        'reText': content,
      };
      
      print('CommentService.updateComment: Request body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json, text/html, */*',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          if (ApiService.cookies.isNotEmpty) 
            'Cookie': ApiService.cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        },
        body: body.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );
      
      print('CommentService.updateComment: Response status: ${response.statusCode}');
      print('CommentService.updateComment: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final trimmedBody = response.body.trim();
        
        // HTML 응답 감지 (세션 만료)
        if (response.body.toLowerCase().contains('<html>') || 
            response.body.toLowerCase().contains('<!doctype html>')) {
          print('CommentService.updateComment: HTML response detected - session may be expired');
          await SessionManager().handleHtmlResponse();
          return false;
        }
        
        // JSON 응답에서 오류 확인
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            if (data['error'] != null || data['message']?.toString().toLowerCase().contains('error') == true) {
              print('CommentService.updateComment: API returned error: ${data['error'] ?? data['message']}');
              return false;
            }
          } catch (e) {
            print('CommentService.updateComment: JSON parsing failed but continuing: $e');
          }
        }
        
        // HTTP 200이고 HTML이 아니면 성공으로 간주
        print('CommentService.updateComment: Treating as success (HTTP 200, non-HTML)');
        return true;
      }
      
      return false;
    } catch (e) {
      print('CommentService.updateComment: Exception - $e');
      return false;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment({
    required String bbsId,
    required int docNumber,
    required int reSeqno,
    required String userId,
  }) async {
    print('CommentService.deleteComment: START');
    print('CommentService.deleteComment: bbsId=$bbsId, docNumber=$docNumber, reSeqno=$reSeqno, userId=$userId');
    
    try {
      final url = '$baseUrl/bbs/bbsDocReply.do?method=remove&bbsId=$bbsId&docNumber=$docNumber&reSeqno=$reSeqno&userId=$userId';
      
      print('CommentService.deleteComment: Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/html, */*',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          if (ApiService.cookies.isNotEmpty) 
            'Cookie': ApiService.cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        },
      );
      
      print('CommentService.deleteComment: Response status: ${response.statusCode}');
      print('CommentService.deleteComment: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final trimmedBody = response.body.trim();
        
        // HTML 응답 감지 (세션 만료)
        if (response.body.toLowerCase().contains('<html>') || 
            response.body.toLowerCase().contains('<!doctype html>')) {
          print('CommentService.deleteComment: HTML response detected - session may be expired');
          await SessionManager().handleHtmlResponse();
          return false;
        }
        
        // JSON 응답에서 오류 확인
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final data = jsonDecode(response.body);
            if (data['error'] != null || data['message']?.toString().toLowerCase().contains('error') == true) {
              print('CommentService.deleteComment: API returned error: ${data['error'] ?? data['message']}');
              return false;
            }
          } catch (e) {
            print('CommentService.deleteComment: JSON parsing failed but continuing: $e');
          }
        }
        
        // HTTP 200이고 HTML이 아니면 성공으로 간주
        print('CommentService.deleteComment: Treating as success (HTTP 200, non-HTML)');
        return true;
      }
      
      return false;
    } catch (e) {
      print('CommentService.deleteComment: Exception - $e');
      return false;
    }
  }

  // 댓글 목록 조회 (기존 ApiService의 getComments 메서드 활용)
  Future<List<Comment>> getComments(String postId, String bbsId) async {
    final apiService = ApiService();
    return await apiService.getComments(postId, bbsId);
  }
}