class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String? contentUrl;
  final String? contentType;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? customData;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.contentUrl,
    this.contentType,
    required this.timestamp,
    this.isRead = false,
    this.customData,
  });

  /// Map에서 InAppNotification 객체 생성
  factory InAppNotification.fromMap(Map<String, dynamic> map) {
    return InAppNotification(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      contentUrl: map['content_url'],
      contentType: map['content_type'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
      customData: map['custom_data'],
    );
  }

  /// InAppNotification 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'content_url': contentUrl,
      'content_type': contentType,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'custom_data': customData,
    };
  }

  /// 콘텐츠가 있는지 확인
  bool get hasContent => contentUrl != null && contentUrl!.isNotEmpty;

  /// 동적 콘텐츠인지 확인
  bool get isDynamicContent => contentType == 'dynamic_html';

  /// 읽음 처리
  void markAsRead() {
    isRead = true;
  }

  /// 복사본 생성 (불변성 유지)
  InAppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? contentUrl,
    String? contentType,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? customData,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      contentUrl: contentUrl ?? this.contentUrl,
      contentType: contentType ?? this.contentType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      customData: customData ?? this.customData,
    );
  }

  @override
  String toString() {
    return 'InAppNotification(id: $id, title: $title, isRead: $isRead, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InAppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}