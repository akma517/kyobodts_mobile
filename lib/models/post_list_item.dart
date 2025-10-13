import 'post.dart';

class PostListItem {
  final int rownumber;
  final int ctid;
  final int? preDocNum;
  final int? nextDocNum;
  final String bbsId;
  final int docNumber;
  final String docSubject;
  final int docRefCnt;
  final String docRegdate;
  final String userName;
  final int replayCt;
  final String docText;

  PostListItem({
    required this.rownumber,
    required this.ctid,
    this.preDocNum,
    this.nextDocNum,
    required this.bbsId,
    required this.docNumber,
    required this.docSubject,
    required this.docRefCnt,
    required this.docRegdate,
    required this.userName,
    required this.replayCt,
    required this.docText,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    final originalSubject = json['docSubject']?.toString() ?? '';
    final subjectAndReply = _extractReplyCount(originalSubject);
    
    return PostListItem(
      rownumber: int.tryParse(json['rownumber']?.toString() ?? '0') ?? 0,
      ctid: int.tryParse(json['ctid']?.toString() ?? '0') ?? 0,
      preDocNum: json['preDocNum'] != null ? int.tryParse(json['preDocNum'].toString()) : null,
      nextDocNum: json['nextDocNum'] != null ? int.tryParse(json['nextDocNum'].toString()) : null,
      bbsId: json['bbsId']?.toString() ?? '',
      docNumber: int.tryParse(json['docNumber']?.toString() ?? '0') ?? 0,
      docSubject: subjectAndReply['subject']!,
      docRefCnt: int.tryParse(json['docRefCnt']?.toString() ?? '0') ?? 0,
      docRegdate: json['docRegdate']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      replayCt: subjectAndReply['replyCount']!,
      docText: json['docText']?.toString() ?? '',
    );
  }
  
  static Map<String, dynamic> _extractReplyCount(String subject) {
    final regex = RegExp(r'\[(\d+)\]\s*$');
    final match = regex.firstMatch(subject);
    
    if (match != null) {
      final replyCount = int.tryParse(match.group(1) ?? '0') ?? 0;
      final cleanSubject = subject.replaceAll(regex, '').trim();
      return {'subject': cleanSubject, 'replyCount': replyCount};
    }
    
    return {'subject': subject, 'replyCount': 0};
  }

  DateTime get createdAt {
    try {
      String dateStr = docRegdate.trim();
      print('PostListItem.createdAt: Parsing date "$dateStr"');
      
      if (dateStr.isEmpty) {
        print('PostListItem.createdAt: Empty date string, using current time');
        return DateTime.now();
      }
      
      // 다양한 날짜 형식 처리
      String normalizedDate = dateStr;
      
      // 1. 점(.) 구분자 처리: 2025.01.15 또는 2025.1.15
      if (normalizedDate.contains('.')) {
        normalizedDate = normalizedDate.replaceAll('.', '-');
      }
      // 2. 슬래시(/) 구분자 처리: 2025/01/15 또는 2025/1/15
      else if (normalizedDate.contains('/')) {
        normalizedDate = normalizedDate.replaceAll('/', '-');
      }
      
      // 3. 시간 정보 처리
      List<String> parts = normalizedDate.split(' ');
      String datePart = parts[0];
      String timePart = parts.length > 1 ? parts[1] : '00:00:00';
      
      // 4. 날짜 부분 정규화 (YYYY-MM-DD 형식으로)
      List<String> dateComponents = datePart.split('-');
      if (dateComponents.length == 3) {
        // 연도, 월, 일 파싱
        int year = int.parse(dateComponents[0]);
        int month = int.parse(dateComponents[1]);
        int day = int.parse(dateComponents[2]);
        
        // 시간 부분 파싱
        List<String> timeComponents = timePart.split(':');
        int hour = timeComponents.isNotEmpty ? int.parse(timeComponents[0]) : 0;
        int minute = timeComponents.length > 1 ? int.parse(timeComponents[1]) : 0;
        int second = timeComponents.length > 2 ? int.parse(timeComponents[2]) : 0;
        
        final result = DateTime(year, month, day, hour, minute, second);
        print('PostListItem.createdAt: Successfully parsed "$dateStr" -> $result');
        return result;
      }
      
      // 5. 기본 DateTime.parse 시도
      final result = DateTime.parse(normalizedDate);
      print('PostListItem.createdAt: DateTime.parse success for "$dateStr" -> $result');
      return result;
      
    } catch (e) {
      print('PostListItem.createdAt: Date parsing error for "$docRegdate": $e');
      print('PostListItem.createdAt: Using current time as fallback');
      return DateTime.now();
    }
  }

  String get formattedDate {
    final date = createdAt;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // PostListItem을 Post 객체로 변환
  Post toPost(String section) {
    return Post(
      id: docNumber.toString(),
      title: docSubject,
      content: docText, // docText를 content로 매핑
      author: userName,
      createdAt: createdAt,
      viewCount: docRefCnt,
      commentCount: replayCt,
      hasAttachment: false, // 목록에서는 첨부파일 정보가 없음
      section: section,
      attachments: [],
      ctid: ctid,
      docNumber: docNumber,
      fileCnt: 0,
      bbsId: bbsId,
    );
  }
}

class PostListApiResponse {
  final int page;
  final List<PostListItem> rows;
  final String total;
  final String records;

  PostListApiResponse({
    required this.page,
    required this.rows,
    required this.total,
    required this.records,
  });

  factory PostListApiResponse.fromJson(Map<String, dynamic> json) {
    return PostListApiResponse(
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((item) => PostListItem.fromJson(item))
          .toList() ?? [],
      total: json['total']?.toString() ?? '0',
      records: json['records']?.toString() ?? '0',
    );
  }
}