class HtmlContentService {
  static String processHtmlContent(String htmlContent) {
    if (htmlContent.isEmpty) return '';
    
    // SmartEditor2 HTML 콘텐츠 전처리
    String processed = htmlContent;
    
    // 1. 불필요한 스타일 태그 제거
    processed = processed.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
    
    // 2. 스크립트 태그 제거
    processed = processed.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
    
    // 3. 불필요한 속성 제거 (onclick, onload 등)
    processed = processed.replaceAll(RegExp(r'\s+on\w+="[^"]*"'), '');
    
    // 배경색 관련 스타일 완전 제거
    processed = processed.replaceAll(RegExp(r'background-color\s*:\s*[^;]+;?', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'background\s*:\s*[^;]+;?', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'bgcolor\s*=\s*"[^"]*"', caseSensitive: false), '');
    
    // 4. 이미지 태그 처리 - 가로 배치를 세로 배치로 변경
    processed = _processImages(processed);
    
    // 5. 빈 태그 제거
    processed = processed.replaceAll(RegExp(r'<(\w+)[^>]*>\s*</\1>'), '');
    
    // 6. 연속된 공백 정리
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    
    // 7. 줄바꿈 정리
    processed = processed.replaceAll(RegExp(r'<br\s*/?>\s*<br\s*/?>'), '<br>');
    
    return processed.trim();
  }
  
  static String _processImages(String html) {
    // 이미지 태그들을 찾아서 순서대로 처리
    final imgRegex = RegExp(r'<img[^>]*>', caseSensitive: false);
    final matches = imgRegex.allMatches(html).toList();
    
    String processed = html;
    
    // 역순으로 처리하여 인덱스 변화 방지
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final imgTag = match.group(0)!;
      
      // 기존 style 속성 제거
      String cleanImgTag = imgTag.replaceAll(RegExp(r'\s+style="[^"]*"'), '');
      
      // width, height 속성 제거
      cleanImgTag = cleanImgTag.replaceAll(RegExp(r'\s+width="[^"]*"'), '');
      cleanImgTag = cleanImgTag.replaceAll(RegExp(r'\s+height="[^"]*"'), '');
      
      // 새로운 스타일 추가
      if (cleanImgTag.contains('/>')) {
        cleanImgTag = cleanImgTag.replaceAll('/>', ' style="width: 100%; height: auto; display: block; margin: 16px 0;" />');
      } else {
        cleanImgTag = cleanImgTag.replaceAll('>', ' style="width: 100%; height: auto; display: block; margin: 16px 0;">');
      }
      
      processed = processed.replaceFirst(imgTag, cleanImgTag, match.start);
    }
    
    return processed;
  }
  
  static bool hasImages(String htmlContent) {
    return htmlContent.contains(RegExp(r'<img[^>]*>', caseSensitive: false));
  }
  
  static bool hasTables(String htmlContent) {
    return htmlContent.contains(RegExp(r'<table[^>]*>', caseSensitive: false));
  }
}