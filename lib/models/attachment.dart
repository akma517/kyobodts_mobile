class Attachment {
  final int fileID;
  final String logicalFileName;
  final String physicalFileName;
  final String filePath;
  final String ext;
  final int fileSize;
  final String bbsId;
  final int docNumber;

  Attachment({
    required this.fileID,
    required this.logicalFileName,
    required this.physicalFileName,
    required this.filePath,
    required this.ext,
    required this.fileSize,
    required this.bbsId,
    required this.docNumber,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileID: json['fileID'] ?? 0,
      logicalFileName: json['logicalFileName'] ?? '',
      physicalFileName: json['physicalFileName'] ?? '',
      filePath: json['filePath'] ?? '',
      ext: json['ext'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      bbsId: json['bbsId'] ?? '',
      docNumber: json['docNumber'] ?? 0,
    );
  }

  String get fileName => logicalFileName;
  String get fileType => ext;

  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext.toLowerCase());
  bool get isPdf => ext.toLowerCase() == 'pdf';
  bool get isDocument => ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext.toLowerCase());
}