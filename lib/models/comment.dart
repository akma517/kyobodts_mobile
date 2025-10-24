class Comment {
  final String id;
  final String postId;
  final String author;
  final String content;
  final DateTime createdAt;
  final String bbsId;
  final int docNumber;
  final String userId;
  final int seqno;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.bbsId,
    required this.docNumber,
    required this.userId,
    required this.seqno,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      author: json['author'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      bbsId: json['bbsId'] ?? '',
      docNumber: json['docNumber'] ?? 0,
      userId: json['userId'] ?? '',
      seqno: json['seqno'] ?? 0,
    );
  }

  factory Comment.fromApiJson(Map<String, dynamic> json) {
    return Comment(
      id: json['reSeqno'].toString(),
      postId: json['docNumber'].toString(),
      author: json['replyUserName'] ?? '',
      content: json['reText'] ?? '',
      createdAt: _parseReRegdate(json['reRegdate']),
      bbsId: json['bbsId'] ?? '',
      docNumber: json['docNumber'] ?? 0,
      userId: json['replyUserId'] ?? '',
      seqno: json['reSeqno'] ?? 0,
    );
  }
  
  static DateTime _parseReRegdate(dynamic reRegdate) {
    try {
      if (reRegdate == null) return DateTime.now();
      
      String dateStr = reRegdate.toString().trim();
      if (dateStr.isEmpty) return DateTime.now();
      
      // 다양한 날짜 형식 처리
      String normalizedDate = dateStr;
      
      if (normalizedDate.contains('.')) {
        normalizedDate = normalizedDate.replaceAll('.', '-');
      } else if (normalizedDate.contains('/')) {
        normalizedDate = normalizedDate.replaceAll('/', '-');
      }
      
      // 시간 정보 처리
      List<String> parts = normalizedDate.split(' ');
      String datePart = parts[0];
      String timePart = parts.length > 1 ? parts[1] : '00:00:00';
      
      // 날짜 부분 정규화
      List<String> dateComponents = datePart.split('-');
      if (dateComponents.length == 3) {
        int year = int.parse(dateComponents[0]);
        int month = int.parse(dateComponents[1]);
        int day = int.parse(dateComponents[2]);
        
        // 시간 부분 파싱
        List<String> timeComponents = timePart.split(':');
        int hour = timeComponents.isNotEmpty ? int.parse(timeComponents[0]) : 0;
        int minute = timeComponents.length > 1 ? int.parse(timeComponents[1]) : 0;
        int second = timeComponents.length > 2 ? int.parse(timeComponents[2]) : 0;
        
        return DateTime(year, month, day, hour, minute, second);
      }
      
      return DateTime.parse(normalizedDate);
    } catch (e) {
      print('Comment reRegdate parsing error for "$reRegdate": $e');
      return DateTime.now();
    }
  }
}