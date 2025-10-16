import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/attachment.dart';
import 'attachment_service.dart';

class FileService {
  static Future<void> downloadAndOpenFile(BuildContext context, Attachment attachment) async {
    print('🔥 === FileService.downloadAndOpenFile START ===');
    print('🔥 파일명: ${attachment.fileName}');
    print('🔥 파일 크기: ${attachment.fileSize} bytes');
    print('🔥 파일 경로: ${attachment.filePath}');
    print('🔥 물리적 파일명: ${attachment.physicalFileName}');
    print('🔥 확장자: ${attachment.ext}');
    print('🔥 BBS ID: ${attachment.bbsId}');
    print('🔥 문서 번호: ${attachment.docNumber}');
    
    // 권한 확인
    if (Platform.isAndroid) {
      print('🔥 Android 플랫폼 - 저장소 권한 확인 중...');
      final permission = await Permission.storage.request();
      print('🔥 저장소 권한 상태: ${permission.toString()}');
      if (!permission.isGranted) {
        print('❌ 저장소 권한이 거부됨');
        _showErrorDialog(context, '파일 다운로드를 위해 저장소 권한이 필요합니다.');
        return;
      }
      print('✅ 저장소 권한 승인됨');
    } else {
      print('🔥 iOS 플랫폼 - 권한 확인 불필요');
    }

    try {
      print('🔥 로딩 다이얼로그 표시 중...');
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('파일 다운로드 중...'),
            ],
          ),
        ),
      );

      print('🔥 AttachmentService를 통한 파일 다운로드 시작...');
      // 파일 다운로드
      final attachmentService = AttachmentService();
      final fileBytes = await attachmentService.downloadFile(attachment);
      
      print('🔥 API 응답 검증 중...');
      if (fileBytes == null) {
        print('❌ 파일 다운로드 실패 - null 응답');
        Navigator.pop(context);
        _showErrorDialog(context, '서버에서 파일을 찾을 수 없습니다.');
        return;
      }
      
      if (fileBytes.isEmpty) {
        print('❌ 파일 다운로드 실패 - 빈 응답');
        Navigator.pop(context);
        _showErrorDialog(context, '다운로드된 파일이 비어있습니다.');
        return;
      }
      
      print('✅ 파일 다운로드 성공 - ${fileBytes.length} bytes 받음');

      // iOS 파일 앱에서 접근 가능한 디렉토리에 파일 저장
      print('🔥 파일 저장 디렉토리 확인 중...');
      Directory appDir;
      if (Platform.isIOS) {
        // iOS: 파일 앱에서 접근 가능한 디렉토리 사용
        appDir = await getApplicationDocumentsDirectory();
        // Downloads 폴더 생성
        final downloadsDir = Directory('${appDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        appDir = downloadsDir;
      } else {
        // Android: 외부 저장소 사용
        appDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
      print('🔥 앱 디렉토리: ${appDir.path}');
      print('🔥 디렉토리 존재 여부: ${await Directory(appDir.path).exists()}');
      
      final filePath = '${appDir.path}/${attachment.fileName}';
      print('🔥 파일 저장 경로: $filePath');
      
      final file = File(filePath);
      print('🔥 파일 쓰기 시작...');
      await file.writeAsBytes(fileBytes);
      print('🔥 파일 쓰기 완료');
      
      // 파일 저장 검증
      final fileExists = await file.exists();
      print('🔥 파일 존재 확인: $fileExists');
      
      if (!fileExists) {
        print('❌ 파일 저장 실패 - 파일이 생성되지 않음');
        Navigator.pop(context);
        _showErrorDialog(context, '파일 저장에 실패했습니다.');
        return;
      }
      
      final savedFileSize = await file.length();
      print('🔥 저장된 파일 크기: $savedFileSize bytes');
      print('🔥 원본 파일 크기: ${fileBytes.length} bytes');
      
      if (savedFileSize != fileBytes.length) {
        print('⚠️ 파일 크기 불일치 - 저장: $savedFileSize, 원본: ${fileBytes.length}');
      }
      
      if (savedFileSize == 0) {
        print('❌ 저장된 파일이 비어있음');
        Navigator.pop(context);
        _showErrorDialog(context, '저장된 파일이 비어있습니다.');
        return;
      }

      Navigator.pop(context); // 로딩 다이얼로그 닫기
      print('🔥 로딩 다이얼로그 닫음');

      // 성공 토스트 알림 표시
      final locationMessage = Platform.isIOS 
          ? '파일 앱 > 내 iPhone > 교보DTS > Downloads 폴더에서 확인 가능'
          : '다운로드 폴더에 저장됨';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('파일 다운로드 완료: ${attachment.fileName}'),
              Text(locationMessage, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      print('✅ 파일 다운로드 성공 토스트 알림 표시');
      print('✅ 최종 파일 경로: $filePath');
      
    } catch (e, stackTrace) {
      print('❌ 파일 다운로드 중 오류 발생: $e');
      print('❌ 오류 스택 트레이스: $stackTrace');
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showErrorDialog(context, '파일 다운로드 중 오류가 발생했습니다:\n$e');
    }
    
    print('🔥 === FileService.downloadAndOpenFile END ===');
  }



  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  static IconData getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
}