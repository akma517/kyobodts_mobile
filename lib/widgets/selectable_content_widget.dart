import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/html_parser.dart';

class SelectableContentWidget extends StatelessWidget {
  final String htmlContent;
  final TextStyle? defaultTextStyle;

  const SelectableContentWidget({
    super.key,
    required this.htmlContent,
    this.defaultTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (htmlContent.isEmpty) {
      return const SelectableText('내용이 없습니다.');
    }

    final parsedContent = HtmlParser.parseHtml(htmlContent);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 텍스트 콘텐츠
        if (parsedContent.text.isNotEmpty)
          SelectableText(
            parsedContent.text,
            style: defaultTextStyle ?? TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        
        // 이미지들
        if (parsedContent.images.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...parsedContent.images.map((imageUrl) => Container(
            width: contentWidth,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(imageUrl, contentWidth),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildImage(String imageUrl, double contentWidth) {
    // base64 데이터 URL 처리
    if (imageUrl.startsWith('data:image/')) {
      return _buildBase64Image(imageUrl, contentWidth);
    }
    
    // 일반 이미지 URL
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: contentWidth,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: contentWidth,
          height: 200,
          color: Colors.grey.shade200,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: contentWidth,
          height: 200,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBase64Image(String dataUrl, double contentWidth) {
    try {
      final base64String = dataUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        width: contentWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: contentWidth,
            height: 200,
            color: Colors.grey.shade200,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        width: contentWidth,
        height: 200,
        color: Colors.grey.shade200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }
}