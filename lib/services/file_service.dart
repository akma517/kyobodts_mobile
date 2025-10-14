import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/attachment.dart';
import 'attachment_service.dart';

class FileService {
  static Future<void> downloadAndOpenFile(BuildContext context, Attachment attachment) async {
    print('=== FileService.downloadAndOpenFile START ===');
    print('파일명: ${attachment.fileName}');
    print('파일 크기: ${attachment.fileSize} bytes');
    print('파일 경로: ${attachment.filePath}');
    print('물리적 파일명: ${attachment.physicalFileName}');
    print('확장자: ${attachment.ext}');
    print('BBS ID: ${attachment.bbsId}');
    print('문서 번호: ${attachment.docNumber}');
    
    // 권한 확인
    if (Platform.isAndroid) {
      print('Android 플랫폼 - 저장소 권한 확인 중...');
      final permission = await Permission.storage.request();
      print('저장소 권한 상태: ${permission.toString()}');
      if (!permission.isGranted) {
        print('저장소 권한이 거부됨');
        _showErrorDialog(context, '파일 다운로드를 위해 저장소 권한이 필요합니다.');
        return;
      }
      print('저장소 권한 승인됨');
    } else {
      print('iOS 플랫폼 - 권한 확인 불필요');
    }

    try {
      print('로딩 다이얼로그 표시 중...');
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

      print('AttachmentService를 통한 파일 다운로드 시작...');
      // 파일 다운로드
      final attachmentService = AttachmentService();
      final fileBytes = await attachmentService.downloadFile(attachment);
      
      if (fileBytes == null) {
        print('파일 다운로드 실패 - null 응답');
        throw Exception('파일 다운로드 실패');
      }
      
      print('파일 다운로드 성공 - ${fileBytes.length} bytes 받음');

      // 앱 문서 디렉토리에 파일 저장
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/${attachment.fileName}';
      print('파일 저장 경로: $filePath');
      
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      final savedFileSize = await file.length();
      print('파일 저장 완료 - 저장된 크기: $savedFileSize bytes');
      print('파일 존재 확인: ${await file.exists()}');

      Navigator.pop(context); // 로딩 다이얼로그 닫기
      print('로딩 다이얼로그 닫음');

      // 성공 토스트 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('파일 다운로드에 성공하였습니다'),
          backgroundColor: Colors.grey,
        ),
      );
      print('파일 다운로드 성공 토스트 알림 표시');
    } catch (e) {
      print('파일 다운로드 중 오류 발생: $e');
      print('오류 스택 트레이스: ${StackTrace.current}');
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showErrorDialog(context, '파일 다운로드 중 오류가 발생했습니다: $e');
    }
    
    print('=== FileService.downloadAndOpenFile END ===');
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