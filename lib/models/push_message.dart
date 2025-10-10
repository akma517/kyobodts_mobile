class PushMessage {
  final String title;
  final String body;
  final String? contentUrl;
  final String? contentType;
  final Map<String, dynamic> data;

  PushMessage({
    required this.title,
    required this.body,
    this.contentUrl,
    this.contentType,
    required this.data,
  });

  factory PushMessage.fromMap(Map<String, dynamic> map) {
    return PushMessage(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      contentUrl: map['content_url'],
      contentType: map['content_type'],
      data: map,
    );
  }

  bool get hasContent => contentUrl != null && contentUrl!.isNotEmpty;
  
  String get contentTypeEnum {
    switch (contentType?.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'asset':
        return 'asset';
      default:
        return 'html';
    }
  }
}