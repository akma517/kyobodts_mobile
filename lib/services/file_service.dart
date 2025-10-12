import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/attachment.dart';

class FileService {
  static Future<void> downloadAndOpenFile(BuildContext context, Attachment attachment) async {
    try {
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

      // 파일 다운로드
      final response = await http.get(Uri.parse(attachment.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('파일 다운로드 실패');
      }

      // 임시 디렉토리에 파일 저장
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${attachment.fileName}');
      await file.writeAsBytes(response.bodyBytes);

      Navigator.pop(context); // 로딩 다이얼로그 닫기

      // 파일 열기
      await _openFile(context, file, attachment);
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showErrorDialog(context, '파일 다운로드 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> _openFile(BuildContext context, File file, Attachment attachment) async {
    try {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showFileOptionsDialog(context, file, attachment);
      }
    } catch (e) {
      _showFileOptionsDialog(context, file, attachment);
    }
  }

  static void _showFileOptionsDialog(BuildContext context, File file, Attachment attachment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attachment.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('파일 크기: ${attachment.formattedFileSize}'),
            Text('파일 형식: ${attachment.fileType.toUpperCase()}'),
            const SizedBox(height: 8),
            const Text('파일이 다운로드되었습니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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