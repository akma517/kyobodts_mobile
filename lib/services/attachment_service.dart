import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attachment.dart';
import 'session_manager.dart';

class AttachmentService {
  static const String baseUrl = 'https://km.kyobodts.co.kr';

  Future<List<Attachment>> getAttachments(String bbsId, int docNumber) async {
    print('=== AttachmentService.getAttachments START ===');
    print('bbsId: $bbsId, docNumber: $docNumber');
    
    try {
      final cookies = await SessionManager.getCookies();
      print('쿠키 가져오기 완료: ${cookies.isNotEmpty ? "쿠키 있음" : "쿠키 없음"}');
      
      final url = '$baseUrl/bbs/bbsAttach.do?method=listView&bbsId=$bbsId&docNumber=$docNumber';
      print('첨부파일 목록 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookies,
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문 크기: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body;
        print('응답 본문 미리보기: $bodyPreview');
        
        final data = json.decode(response.body);
        print('JSON 파싱 성공');
        print('응답 데이터 키: ${data.keys.toList()}');
        
        final fileList = data['fileList'] as List?;
        print('fileList 존재 여부: ${fileList != null}');
        
        if (fileList != null) {
          print('fileList 크기: ${fileList.length}');
          final attachments = fileList.map((json) {
            print('첨부파일 파싱: ${json['logicalFileName']} (${json['fileSize']} bytes)');
            return Attachment.fromJson(json);
          }).toList();
          print('첨부파일 목록 조회 성공: ${attachments.length}개');
          return attachments;
        } else {
          print('첨부파일 목록이 비어있음');
        }
      } else {
        print('첨부파일 목록 조회 실패 - HTTP 상태 코드: ${response.statusCode}');
        print('오류 응답: ${response.body}');
      }
      return [];
    } catch (e) {
      print('첨부파일 목록 조회 중 예외 발생: $e');
      print('예외 스택 트레이스: ${StackTrace.current}');
      return [];
    } finally {
      print('=== AttachmentService.getAttachments END ===');
    }
  }

  Future<List<int>?> downloadFile(Attachment attachment) async {
    print('=== AttachmentService.downloadFile START ===');
    print('다운로드 요청 파라미터:');
    print('  filePath: ${attachment.filePath}');
    print('  logicalFileName: ${attachment.logicalFileName}');
    print('  physicalFileName: ${attachment.physicalFileName}');
    print('  ext: ${attachment.ext}');
    
    try {
      final cookies = await SessionManager.getCookies();
      print('쿠키 가져오기 완료: ${cookies.isNotEmpty ? "쿠키 있음" : "쿠키 없음"}');
      if (cookies.isNotEmpty) {
        print('쿠키 내용 (처음 100자): ${cookies.length > 100 ? cookies.substring(0, 100) + "..." : cookies}');
      }
      
      final url = '$baseUrl/common/filedownload.do?method=download';
      print('다운로드 URL: $url');
      
      final requestBody = {
        'filePath': attachment.filePath,
        'logicalFileName': attachment.logicalFileName,
        'physicalFileName': attachment.physicalFileName,
        'ext': attachment.ext,
      };
      print('요청 본문: $requestBody');
      
      print('HTTP POST 요청 전송 중...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cookie': cookies,
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
        },
        body: requestBody,
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문 크기: ${response.bodyBytes.length} bytes');
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        print('콘텐츠 타입: $contentType');
        
        // HTML 응답인지 확인 (로그인 페이지로 리다이렉트된 경우)
        if (contentType.toLowerCase().contains('text/html')) {
          final bodyPreview = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
          print('경고: HTML 응답 감지 - 로그인 필요할 수 있음');
          print('HTML 내용 미리보기: $bodyPreview');
          return null;
        }
        
        print('파일 다운로드 성공: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('파일 다운로드 실패 - HTTP 상태 코드: ${response.statusCode}');
        print('오류 응답 본문: ${response.body}');
      }
      return null;
    } catch (e) {
      print('파일 다운로드 중 예외 발생: $e');
      print('예외 스택 트레이스: ${StackTrace.current}');
      return null;
    } finally {
      print('=== AttachmentService.downloadFile END ===');
    }
  }
}