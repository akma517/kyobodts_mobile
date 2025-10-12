import 'attachment.dart';

class Post {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final int viewCount;
  final int commentCount;
  final bool hasAttachment;
  final String section;
  final List<Attachment> attachments;
  final int ctid;
  final int docNumber;
  final int fileCnt;
  final String bbsId;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.viewCount,
    required this.commentCount,
    required this.hasAttachment,
    required this.section,
    this.attachments = const [],
    required this.ctid,
    required this.docNumber,
    required this.fileCnt,
    required this.bbsId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      viewCount: json['viewCount'],
      commentCount: json['commentCount'],
      hasAttachment: json['hasAttachment'],
      section: json['section'],
      ctid: json['ctid'] ?? 0,
      docNumber: json['docNumber'] ?? 0,
      fileCnt: json['fileCnt'] ?? 0,
      bbsId: json['bbsId'] ?? '',
    );
  }

  factory Post.fromApiJson(Map<String, dynamic> json) {
    // replayCt에서 숫자만 추출 (예: " [19]" -> 19)
    int commentCount = 0;
    if (json['replayCt'] != null) {
      final replayStr = json['replayCt'].toString();
      final match = RegExp(r'\[(\d+)\]').firstMatch(replayStr);
      if (match != null) {
        commentCount = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    return Post(
      id: json['docNumber'].toString(),
      title: json['docSubject'] ?? '',
      content: json['docText'] ?? '',
      author: json['userName'] ?? '',
      createdAt: DateTime.parse(json['docRegdate'] + ' 00:00:00'),
      viewCount: json['docRefCnt'] ?? 0,
      commentCount: commentCount,
      hasAttachment: (json['fileCnt'] ?? 0) > 0,
      section: '',
      ctid: json['ctid'] ?? 0,
      docNumber: json['docNumber'] ?? 0,
      fileCnt: json['fileCnt'] ?? 0,
      bbsId: json['bbsId'] ?? '',
    );
  }
}