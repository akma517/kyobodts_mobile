class Attachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  Attachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileType.toLowerCase());
  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isDocument => ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(fileType.toLowerCase());
}