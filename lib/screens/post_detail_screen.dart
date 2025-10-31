import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/attachment.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../services/comment_service.dart';
import '../services/attachment_service.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/selectable_content_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final CommentService _commentService = CommentService();
  final AttachmentService _attachmentService = AttachmentService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> comments = [];
  List<Attachment> attachments = [];
  bool isLoading = true;
  bool isLoadingAttachments = false;

  @override
  void initState() {
    super.initState();
    _logPostData();
    _loadComments();
    _loadAttachments();
  }
  
  void _logPostData() {
    print('=== PostDetailScreen: 주입받은 Post 데이터 ===');
    print('Post ID: ${widget.post.id}');
    print('Title: ${widget.post.title}');
    print('Author: ${widget.post.author}');
    print('Section: ${widget.post.section}');
    print('Created At: ${widget.post.createdAt}');
    print('View Count: ${widget.post.viewCount}');
    print('Comment Count: ${widget.post.commentCount}');
    print('Has Attachment: ${widget.post.hasAttachment}');
    print('Content Length: ${widget.post.content.length}');
    print('Content Preview: ${widget.post.content.length > 100 ? widget.post.content.substring(0, 100) + "..." : widget.post.content}');
    print('Attachments Count: ${widget.post.attachments.length}');
    print('CTID: ${widget.post.ctid}');
    print('Doc Number: ${widget.post.docNumber}');
    print('File Count: ${widget.post.fileCnt}');
    print('BBS ID: ${widget.post.bbsId}');
    if (widget.post.attachments.isNotEmpty) {
      print('Attachments:');
      for (int i = 0; i < widget.post.attachments.length; i++) {
        final attachment = widget.post.attachments[i];
        print('  [$i] ${attachment.fileName} (${attachment.fileType}, ${attachment.fileSize} bytes)');
      }
    }
    print('=== End Post 데이터 ===');
  }

  Future<void> _loadComments() async {
    print('PostDetailScreen._loadComments: START');
    print('PostDetailScreen._loadComments: Current user: ${_authService.currentUser?.id} (${_authService.currentUser?.name})');
    print('PostDetailScreen._loadComments: Post docNumber: ${widget.post.docNumber}, bbsId: ${widget.post.bbsId}');
    
    if (mounted) {
      setState(() => isLoading = true);
    }
    
    final loadedComments = await _postService.getComments(widget.post.docNumber.toString(), bbsId: widget.post.bbsId);
    print('PostDetailScreen._loadComments: Loaded ${loadedComments.length} comments');
    
    for (int i = 0; i < loadedComments.length; i++) {
      final comment = loadedComments[i];
      print('PostDetailScreen._loadComments: Comment[$i] - author: ${comment.author}, userId: ${comment.userId}, content: ${comment.content.length > 50 ? comment.content.substring(0, 50) + "..." : comment.content}');
    }
    
    if (mounted) {
      setState(() {
        comments = loadedComments;
        isLoading = false;
      });
    }
    
    print('PostDetailScreen._loadComments: Comments loaded and UI updated');
  }

  Future<void> _loadAttachments() async {
    if (widget.post.hasAttachment) {
      setState(() => isLoadingAttachments = true);
      
      final loadedAttachments = await _attachmentService.getAttachments(
        widget.post.bbsId, 
        widget.post.docNumber
      );
      
      if (mounted) {
        setState(() {
          attachments = loadedAttachments;
          isLoadingAttachments = false;
        });
      }
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();
    
    // 키패드 내리기
    FocusScope.of(context).unfocus();

    final newComment = await _postService.addComment(
      widget.post.docNumber.toString(), 
      content,
      bbsId: widget.post.bbsId,
    );
    if (!mounted) return;
    
    if (newComment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 작성되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
      );
    }
    
    // 성공/실패 여부와 관계없이 댓글 목록 새로고침
    await _loadComments();
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              if (!mounted) return;
              
              final success = await _postService.deleteComment(commentId);
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('댓글이 삭제되었습니다.')),
                );
                // 성공 시에만 댓글 목록 새로고침
                await _loadComments();
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
          if (!mounted) return;
          
          final success = await _postService.updateComment(comment.id, content);
          
          if (!mounted) return;
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('댓글이 수정되었습니다.')),
            );
            // 성공 시에만 댓글 목록 새로고침
            await _loadComments();
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
    return Scaffold(
      appBar: CommonAppBar(title: widget.post.section),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadComments();
                await _loadAttachments();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                SelectableText(
                                  widget.post.title,
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
                                          widget.post.author[0],
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
                                            SelectableText(
                                              widget.post.author,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            SelectableText(
                                              _formatDate(widget.post.createdAt),
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
                                                  '${widget.post.viewCount}',
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
                            child: SelectableContentWidget(
                              htmlContent: widget.post.content,
                              defaultTextStyle: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // 첨부파일 섹션
                          if (widget.post.hasAttachment || widget.post.fileCnt > 0) ...{
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
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isLoadingAttachments 
                                          ? '첨부파일 로딩 중...' 
                                          : attachments.isNotEmpty 
                                            ? '첨부파일 (${attachments.length}개)'
                                            : '첨부파일 (${widget.post.fileCnt}개)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (isLoadingAttachments)
                                    const Center(child: CircularProgressIndicator())
                                  else if (attachments.isEmpty && widget.post.fileCnt > 0)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '첨부파일이 있지만 로드에 실패했습니다. 새로고침을 시도해주세요.',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...attachments.map((attachment) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          FileService.getFileIcon(attachment.fileType),
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        onTap: () => FileService.downloadAndOpenFile(context, attachment),
                                      ),
                                    )),
                                ],
                              ),
                            ),
                          },
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
                            isLoading ? '댓글 로딩 중...' : '댓글 ${comments.length}개',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 댓글 로딩 또는 목록
                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
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
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              SelectableText(
                                                comment.author,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SelectableText(
                                                _formatCommentDate(comment.createdAt),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: comment.userId == _authService.currentUser?.id
                                            ? PopupMenuButton(
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
                                                  print('PostDetailScreen: Comment action selected - $value for comment by ${comment.author} (userId: ${comment.userId})');
                                                  print('PostDetailScreen: Current user: ${_authService.currentUser?.id} (${_authService.currentUser?.name})');
                                                  
                                                  if (value == 'edit') {
                                                    _editComment(comment);
                                                  } else if (value == 'delete') {
                                                    _deleteComment(comment.id);
                                                  }
                                                },
                                              )
                                            : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 0),
                                    SelectableText(
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
      floatingActionButton: kDebugMode ? FloatingActionButton(
        mini: true,
        onPressed: _testCommentCrud,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.bug_report),
      ) : null,
    );
  }

  void _testCommentCrud() async {
    print('=== Comment CRUD Test START ===');
    
    try {
      // Test 1: Create comment
      print('Test 1: Creating comment...');
      final newComment = await _commentService.createComment(
        bbsId: widget.post.bbsId,
        docNumber: widget.post.docNumber,
        content: 'Test comment from CRUD test',
      );
      
      if (newComment != null) {
        print('✅ Comment created successfully: ${newComment.id}');
        
        // Test 2: Update comment (using mock data for seqno)
        print('Test 2: Updating comment...');
        final updateSuccess = await _commentService.updateComment(
          bbsId: widget.post.bbsId,
          docNumber: widget.post.docNumber,
          reSeqno: 1, // Mock seqno
          content: 'Updated test comment',
          userId: newComment.userId,
        );
        
        if (updateSuccess) {
          print('✅ Comment updated successfully');
        } else {
          print('❌ Comment update failed');
        }
        
        // Test 3: Delete comment
        print('Test 3: Deleting comment...');
        final deleteSuccess = await _commentService.deleteComment(
          bbsId: widget.post.bbsId,
          docNumber: widget.post.docNumber,
          reSeqno: 1, // Mock seqno
          userId: newComment.userId,
        );
        
        if (deleteSuccess) {
          print('✅ Comment deleted successfully');
        } else {
          print('❌ Comment delete failed');
        }
      } else {
        print('❌ Comment creation failed');
      }
    } catch (e) {
      print('❌ Comment CRUD test error: $e');
    }
    
    print('=== Comment CRUD Test END ===');
    
    // Refresh comments after test
    await _loadComments();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  String _formatCommentDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
              // 키패드 내리기
              FocusScope.of(context).unfocus();
              widget.onUpdate(content);
              Navigator.pop(context);
            }
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}