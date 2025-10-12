class Comment {
  final String id;
  final String postId;
  final String author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      author: json['author'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}