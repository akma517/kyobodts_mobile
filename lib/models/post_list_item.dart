class PostListItem {
  final int rownumber;
  final int ctid;
  final int? preDocNum;
  final int? nextDocNum;
  final String bbsId;
  final int docNumber;
  final String docSubject;
  final int docRefCnt;
  final String docRegDate;
  final String userName;
  final int replayCt;

  PostListItem({
    required this.rownumber,
    required this.ctid,
    this.preDocNum,
    this.nextDocNum,
    required this.bbsId,
    required this.docNumber,
    required this.docSubject,
    required this.docRefCnt,
    required this.docRegDate,
    required this.userName,
    required this.replayCt,
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
      docRegDate: json['docRegDate']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      replayCt: subjectAndReply['replyCount']!,
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
      String dateStr = docRegDate;
      if (dateStr.contains('.')) {
        dateStr = dateStr.replaceAll('.', '-');
      }
      if (!dateStr.contains(' ')) {
        dateStr += ' 00:00:00';
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    final date = createdAt;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
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