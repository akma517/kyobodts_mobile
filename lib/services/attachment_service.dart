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
    print('🔥 === AttachmentService.downloadFile START ===');
    print('🔥 다운로드 요청 파라미터:');
    print('🔥   filePath: ${attachment.filePath}');
    print('🔥   logicalFileName: ${attachment.logicalFileName}');
    print('🔥   physicalFileName: ${attachment.physicalFileName}');
    print('🔥   ext: ${attachment.ext}');
    print('🔥   fileSize: ${attachment.fileSize}');
    print('🔥   fileID: ${attachment.fileID}');
    
    try {
      final cookies = await SessionManager.getCookies();
      print('🔥 쿠키 가져오기 완료: ${cookies.isNotEmpty ? "쿠키 있음" : "쿠키 없음"}');
      if (cookies.isNotEmpty) {
        print('🔥 쿠키 내용 (처음 100자): ${cookies.length > 100 ? cookies.substring(0, 100) + "..." : cookies}');
      } else {
        print('⚠️ 쿠키가 비어있음 - 인증 문제 가능성');
      }
      
      final url = '$baseUrl/common/filedownload.do?method=download';
      print('🔥 다운로드 URL: $url');
      
      final requestBody = {
        'filePath': attachment.filePath,
        'logicalFileName': attachment.logicalFileName,
        'physicalFileName': attachment.physicalFileName,
        'ext': attachment.ext,
      };
      print('🔥 요청 본문: $requestBody');
      
      // 요청 본문 검증
      final emptyFields = requestBody.entries.where((e) => e.value == null || e.value.toString().isEmpty).map((e) => e.key).toList();
      if (emptyFields.isNotEmpty) {
        print('⚠️ 빈 필드 발견: $emptyFields');
      }
      
      print('🔥 HTTP POST 요청 전송 중...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cookie': cookies,
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
        },
        body: requestBody,
      );

      print('🔥 응답 수신 완료');
      print('🔥 응답 상태 코드: ${response.statusCode}');
      print('🔥 응답 헤더: ${response.headers}');
      print('🔥 응답 본문 크기: ${response.bodyBytes.length} bytes');
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        final contentLength = response.headers['content-length'] ?? '0';
        final contentDisposition = response.headers['content-disposition'] ?? '';
        
        print('🔥 콘텐츠 타입: $contentType');
        print('🔥 콘텐츠 길이: $contentLength');
        print('🔥 콘텐츠 배치: $contentDisposition');
        
        // 빈 응답 검사
        if (response.bodyBytes.isEmpty) {
          print('❌ 빈 응답 받음');
          return null;
        }
        
        // HTML 응답인지 확인 (로그인 페이지로 리다이렉트된 경우)
        if (contentType.toLowerCase().contains('text/html')) {
          final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
          print('❌ 경고: HTML 응답 감지 - 로그인 필요할 수 있음');
          print('❌ HTML 내용 미리보기: $bodyPreview');
          
          // 로그인 페이지 감지
          if (bodyPreview.contains('login') || bodyPreview.contains('로그인')) {
            print('❌ 로그인 페이지로 리다이렉트됨');
          }
          return null;
        }
        
        // 예상 콘텐츠 타입 검증
        final validTypes = ['application/octet-stream', 'application/pdf', 'image/', 'application/msword', 'application/vnd.', 'application/zip'];
        final isValidType = validTypes.any((type) => contentType.toLowerCase().contains(type)) || contentType.isEmpty;
        
        if (!isValidType) {
          print('⚠️ 예상치 못한 콘텐츠 타입: $contentType');
        }
        
        // 데이터 무결성 검사
        final actualSize = response.bodyBytes.length;
        final expectedSize = int.tryParse(contentLength) ?? 0;
        
        if (expectedSize > 0 && actualSize != expectedSize) {
          print('⚠️ 파일 크기 불일치 - 예상: $expectedSize, 실제: $actualSize');
        }
        
        // 데이터 샘플 출력
        if (response.bodyBytes.isNotEmpty) {
          final sampleSize = response.bodyBytes.length < 50 ? response.bodyBytes.length : 50;
          final sample = response.bodyBytes.take(sampleSize).toList();
          print('🔥 데이터 샘플 (hex): ${sample.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          
          // 파일 시그니처 검사
          if (sample.length >= 4) {
            final signature = sample.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
            print('🔥 파일 시그니처: $signature');
            
            // 알려진 파일 시그니처 확인
            final signatures = {
              '25504446': 'PDF',
              'FFD8FFE0': 'JPEG',
              '89504E47': 'PNG',
              '504B0304': 'ZIP/Office',
              'D0CF11E0': 'MS Office',
            };
            
            final detectedType = signatures[signature];
            if (detectedType != null) {
              print('🔥 감지된 파일 타입: $detectedType');
            }
          }
        }
        
        print('✅ 파일 다운로드 성공: $actualSize bytes');
        return response.bodyBytes;
      } else {
        print('❌ 파일 다운로드 실패 - HTTP 상태 코드: ${response.statusCode}');
        print('❌ 오류 응답 헤더: ${response.headers}');
        print('❌ 오류 응답 본문: ${response.body}');
        
        // 상태 코드별 상세 오류 메시지
        switch (response.statusCode) {
          case 401:
            print('❌ 인증 실패 - 로그인 필요');
            break;
          case 403:
            print('❌ 접근 금지 - 권한 부족');
            break;
          case 404:
            print('❌ 파일을 찾을 수 없음');
            break;
          case 500:
            print('❌ 서버 내부 오류');
            break;
        }
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ 파일 다운로드 중 예외 발생: $e');
      print('❌ 예외 스택 트레이스: $stackTrace');
      return null;
    } finally {
      print('🔥 === AttachmentService.downloadFile END ===');
    }
  }
}