import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../widgets/common_app_bar.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String section;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.section,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  Post? post;
  List<Comment> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
  }

  void _loadPostDetail() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    
    final loadedPost = await _postService.getPost(widget.postId);
    final loadedComments = await _postService.getComments(widget.postId);
    
    if (mounted) {
      setState(() {
        post = loadedPost;
        comments = loadedComments;
        isLoading = false;
      });
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();

    final newComment = await _postService.addComment(widget.postId, content);
    if (!mounted) return;
    
    if (newComment != null) {
      setState(() {
        comments.add(newComment);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 작성되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
      );
    }
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _postService.deleteComment(commentId);
              if (!mounted) return;
              
              if (success) {
                setState(() {
                  comments.removeWhere((comment) => comment.id == commentId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('댓글이 삭제되었습니다.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('댓글 삭제에 실패했습니다.')),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _editComment(Comment comment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _EditCommentDialog(
        comment: comment,
        onUpdate: (content) async {
          final success = await _postService.updateComment(comment.id, content);
          if (!mounted) return;
          
          if (success) {
            setState(() {
              final index = comments.indexWhere((c) => c.id == comment.id);
              if (index != -1) {
                comments[index] = Comment(
                  id: comment.id,
                  postId: comment.postId,
                  author: comment.author,
                  content: content,
                  createdAt: comment.createdAt,
                );
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('댓글이 수정되었습니다.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('댓글 수정에 실패했습니다.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: CommonAppBar(title: widget.section),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (post == null) {
      return Scaffold(
        appBar: CommonAppBar(title: widget.section),
        body: const Center(child: Text('게시글을 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(title: widget.section),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 게시글 헤더 + 본문
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 섹션
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post!.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Text(
                                        post!.author[0],
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post!.author,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(post!.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.visibility,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${post!.viewCount}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.chat_bubble_outline,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${comments.length}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 구분선
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                        // 본문 섹션
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            post!.content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // 첨부파일 섹션
                        if (post!.attachments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '첨부파일 (${post!.attachments.length}개)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...post!.attachments.map((attachment) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      FileService.getFileIcon(attachment.fileType),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(
                                      attachment.fileName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${attachment.fileType.toUpperCase()} · ${attachment.formattedFileSize}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.download,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onTap: () => FileService.downloadAndOpenFile(context, attachment),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 댓글 섹션
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '댓글 ${comments.length}개',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 댓글 목록
                        ...comments.map((comment) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.author,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(comment.createdAt),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    if (comment.author == _authService.currentUser?.name)
                                      PopupMenuButton(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 16),
                                                SizedBox(width: 8),
                                                Text('수정'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 16),
                                                SizedBox(width: 8),
                                                Text('삭제'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editComment(comment);
                                          } else if (value == 'delete') {
                                            _deleteComment(comment.id);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comment.content,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 댓글 작성
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('작성'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class _EditCommentDialog extends StatefulWidget {
  final Comment comment;
  final Function(String) onUpdate;

  const _EditCommentDialog({
    required this.comment,
    required this.onUpdate,
  });

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('댓글 수정'),
      content: TextField(
        controller: _editController,
        decoration: const InputDecoration(
          hintText: '댓글을 수정하세요',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            if (_editController.text.trim().isNotEmpty) {
              final content = _editController.text.trim();
              Navigator.pop(context);
              widget.onUpdate(content);
            }
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}