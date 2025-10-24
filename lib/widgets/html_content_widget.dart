import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/html_content_service.dart';

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final TextStyle? defaultTextStyle;

  const HtmlContentWidget({
    super.key,
    required this.htmlContent,
    this.defaultTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (htmlContent.isEmpty) {
      return const Text('내용이 없습니다.');
    }

    final processedHtml = HtmlContentService.processHtmlContent(htmlContent);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 32; // 패딩 16*2
    
    return HtmlWidget(
      '<style>* { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important; font-size: 16px !important; line-height: 1.1 !important; margin: 0 !important; background-color: transparent !important; background: transparent !important; border: none !important; padding: 0 !important; } b, strong { font-weight: bold !important; } u { text-decoration: underline !important; } s, strike, del { text-decoration: line-through !important; } br { margin: 0; line-height: 1.1; } p { margin: 0; line-height: 1.1; }</style>$processedHtml',
      textStyle: TextStyle(
        fontSize: 16,
        height: 1.1,
        fontWeight: FontWeight.normal,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      factoryBuilder: () => _CustomWidgetFactory(context, contentWidth),
      onTapUrl: (url) {
        print('Link tapped: $url');
        return true;
      },
    );
  }
}

class _CustomWidgetFactory extends WidgetFactory {
  final BuildContext context;
  final double contentWidth;
  
  _CustomWidgetFactory(this.context, this.contentWidth);
  
  @override
  Widget? buildImageWidget(BuildMetadata meta, ImageSource src) {
    String imageUrl = src.url;
    
    // base64 데이터 URL 처리
    if (imageUrl.startsWith('data:image/')) {
      return _buildBase64Image(imageUrl);
    }
    
    // 상대 경로를 절대 경로로 변환
    if (!imageUrl.startsWith('http')) {
      imageUrl = 'https://gw.kyobodts.co.kr$imageUrl';
    }
    
    return Container(
      width: contentWidth,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
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
        ),
      ),
    );
  }
  
  Widget _buildBase64Image(String dataUrl) {
    try {
      final base64String = dataUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      
      return Container(
        width: contentWidth,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
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
          ),
        ),
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
  
  @override
  Widget? buildTableWidget(BuildMetadata meta, Iterable<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.toList(),
          ),
        ),
      ),
    );
  }
}