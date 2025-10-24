class PushMessage {
  final String title;
  final String body;
  final String? contentUrl;
  final String? contentType;
  final String? action;
  final Map<String, dynamic> data;

  PushMessage({
    required this.title,
    required this.body,
    this.contentUrl,
    this.contentType,
    this.action,
    required this.data,
  });

  factory PushMessage.fromMap(Map<String, dynamic> map) {
    return PushMessage(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      contentUrl: map['content_url'],
      contentType: map['content_type'],
      action: map['action'],
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