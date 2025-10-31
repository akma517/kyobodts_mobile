class HtmlParser {
  static ParsedContent parseHtml(String htmlContent) {
    if (htmlContent.isEmpty) {
      return ParsedContent(text: '', images: []);
    }

    // HTML 태그 제거하여 순수 텍스트 추출
    String plainText = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();

    // 이미지 URL 추출
    List<String> images = [];
    RegExp imgRegex = RegExp(r'src=["' + "'" + r'](.*?)["' + "'" + r']', caseSensitive: false);
    Iterable<RegExpMatch> matches = imgRegex.allMatches(htmlContent);
    
    for (RegExpMatch match in matches) {
      String? imageUrl = match.group(1);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // 상대 경로를 절대 경로로 변환
        if (!imageUrl.startsWith('http') && !imageUrl.startsWith('data:')) {
          imageUrl = 'https://gw.kyobodts.co.kr$imageUrl';
        }
        images.add(imageUrl);
      }
    }

    return ParsedContent(text: plainText, images: images);
  }
}

class ParsedContent {
  final String text;
  final List<String> images;

  ParsedContent({required this.text, required this.images});
}
