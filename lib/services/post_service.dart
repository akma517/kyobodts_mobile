import '../models/post.dart';
import '../models/comment.dart';
import '../models/attachment.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'comment_service.dart';

class PostService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final CommentService _commentService = CommentService();
  
  // 댓글 참조를 저장하기 위한 맵
  final Map<String, Comment> _commentCache = {};
  
  bool get _isTestAccount {
    final isTest = _authService.isTestAccount;
    print('PostService: isTestAccount = $isTest, currentUser = ${_authService.currentUser?.id}');
    return isTest;
  }

  // Mock 데이터
  static final List<Post> _mockPosts = [
    Post(
      id: '1',
      title: '2024년 신년 인사',
      content: '새해 복 많이 받으세요.',
      author: '대표이사',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      viewCount: 150,
      commentCount: 5,
      hasAttachment: false,
      section: '공지사항',
      ctid: 321,
      docNumber: 1,
      fileCnt: 0,
      bbsId: 'B0000111',
    ),
    Post(
      id: '2',
      title: '디지털 전환 교육 안내',
      content: 'DX 교육 프로그램을 시작합니다.',
      author: '교육팀',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      viewCount: 89,
      commentCount: 12,
      hasAttachment: true,
      section: '디지털에듀',
      ctid: 313,
      docNumber: 2,
      fileCnt: 1,
      bbsId: 'B0000039',
      attachments: [
        Attachment(
          fileID: 1,
          logicalFileName: 'DX교육과정.pdf',
          physicalFileName: 'dx-education.pdf',
          filePath: '/files',
          ext: 'pdf',
          fileSize: 2048576,
          bbsId: 'B0000039',
          docNumber: 2,
        ),
      ],
    ),
    Post(
      id: '3',
      title: '회사 창립 기념일 행사',
      content: '창립 기념 행사를 개최합니다.',
      author: '총무팀',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      viewCount: 234,
      commentCount: 8,
      hasAttachment: false,
      section: '회사소식',
      ctid: 172,
      docNumber: 3,
      fileCnt: 0,
      bbsId: 'B0000002',
    ),
    Post(
      id: '4',
      title: '점심 메뉴 추천',
      content: '오늘 점심 뭐 드실래요?',
      author: '김직원',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      viewCount: 45,
      commentCount: 23,
      hasAttachment: false,
      section: '사우소식·자유게시판',
      ctid: 164,
      docNumber: 4,
      fileCnt: 0,
      bbsId: 'B0000004',
    ),
    Post(
      id: '5',
      title: '2024년 하반기 업무계획서',
      content: '하반기 업무계획서를 첨부파일로 공유드립니다. 각 부서별 목표와 추진 계획을 확인해 주시기 바랍니다.',
      author: '기획팀',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      viewCount: 78,
      commentCount: 6,
      hasAttachment: true,
      section: '공지사항',
      ctid: 321,
      docNumber: 5,
      fileCnt: 2,
      bbsId: 'B0000111',
      attachments: [
        Attachment(
          fileID: 2,
          logicalFileName: '2024_하반기_업무계획서.xlsx',
          physicalFileName: 'business-plan-2024.xlsx',
          filePath: '/files',
          ext: 'xlsx',
          fileSize: 1536000,
          bbsId: 'B0000111',
          docNumber: 5,
        ),
        Attachment(
          fileID: 3,
          logicalFileName: '부서별_목표.pdf',
          physicalFileName: 'department-goals.pdf',
          filePath: '/files',
          ext: 'pdf',
          fileSize: 512000,
          bbsId: 'B0000111',
          docNumber: 5,
        ),
      ],
    ),
  ];

  static final List<Comment> _mockComments = [
    Comment(
      id: '1',
      postId: '1',
      author: '홍길동',
      content: '새해 복 많이 받으세요!',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      bbsId: 'B0000111',
      docNumber: 1,
      userId: 'test001',
      seqno: 1,
    ),
    Comment(
      id: '2',
      postId: '1',
      author: '홍길동',
      content: '올해도 잘 부탁드립니다.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      bbsId: 'B0000111',
      docNumber: 1,
      userId: 'test001',
      seqno: 2,
    ),
    Comment(
      id: '3',
      postId: '2',
      author: '홍길동',
      content: 'DX 교육 기대됩니다!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      bbsId: 'B0000039',
      docNumber: 2,
      userId: 'test001',
      seqno: 1,
    ),
  ];

  Future<List<Post>> getPosts({String? section, int page = 1, int limit = 10}) async {
    print('PostService.getPosts: isTestAccount = $_isTestAccount, section = $section');
    
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 500)); // API 지연 시뮬레이션
      
      var posts = _mockPosts;
      if (section != null) {
        posts = posts.where((post) => post.section == section).toList();
      }
      
      print('PostService.getPosts: returning ${posts.length} mock posts');
      return posts;
    } else {
      print('PostService.getPosts: calling real API');
      try {
        final posts = await _apiService.getPosts(section: section, page: page, limit: limit);
        print('PostService.getPosts: API returned ${posts.length} posts');
        return posts;
      } catch (e) {
        print('PostService.getPosts: API error - $e');
        // API 오류 시 빈 리스트 반환
        return [];
      }
    }
  }

  Future<List<Post>> getRecentPosts(String section, {int limit = 5}) async {
    print('PostService.getRecentPosts: isTestAccount = $_isTestAccount, section = $section');
    
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final posts = _mockPosts
          .where((post) => post.section == section)
          .take(limit)
          .toList();
      
      print('PostService.getRecentPosts: returning ${posts.length} mock posts');
      return posts;
    } else {
      print('PostService.getRecentPosts: calling real API');
      try {
        final posts = await _apiService.getRecentPosts(section, limit: limit);
        print('PostService.getRecentPosts: API returned ${posts.length} posts');
        return posts;
      } catch (e) {
        print('PostService.getRecentPosts: API error - $e');
        return [];
      }
    }
  }

  Future<Post?> getPost(String postId) async {
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        return _mockPosts.firstWhere((post) => post.id == postId);
      } catch (e) {
        return null;
      }
    } else {
      // 실제 API 호출
      return await _apiService.getPost(postId);
    }
  }

  Future<List<Comment>> getComments(String postId, {String? bbsId}) async {
    print('PostService.getComments: START - postId: $postId, bbsId: $bbsId, isTestAccount: $_isTestAccount');
    
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final comments = _mockComments.where((comment) => comment.postId == postId).toList();
      print('PostService.getComments: Returning ${comments.length} mock comments');
      
      // 댓글 참조 저장
      for (final comment in comments) {
        _commentCache[comment.id] = comment;
      }
      
      return comments;
    } else {
      // bbsId가 제공되지 않은 경우 기본값 사용
      final actualBbsId = bbsId ?? 'B0000111';
      print('PostService.getComments: Calling API with actualBbsId: $actualBbsId');
      
      final comments = await _apiService.getComments(postId, actualBbsId);
      print('PostService.getComments: API returned ${comments.length} comments');
      
      // 댓글 참조 저장
      for (final comment in comments) {
        _commentCache[comment.id] = comment;
      }
      
      return comments;
    }
  }

  // 댓글 수정
  Future<bool> updateComment(String commentId, String newContent) async {
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final index = _mockComments.indexWhere((comment) => comment.id == commentId);
      if (index != -1) {
        _mockComments[index] = Comment(
          id: _mockComments[index].id,
          postId: _mockComments[index].postId,
          author: _mockComments[index].author,
          content: newContent,
          createdAt: _mockComments[index].createdAt,
          bbsId: _mockComments[index].bbsId,
          docNumber: _mockComments[index].docNumber,
          userId: _mockComments[index].userId,
          seqno: _mockComments[index].seqno,
        );
        return true;
      }
      return false;
    } else {
      // 실제 API 호출 - CommentService 사용
      final comment = _commentCache[commentId];
      if (comment == null) {
        print('PostService.updateComment: Comment not found in cache: $commentId');
        return false;
      }
      
      return await _commentService.updateComment(
        bbsId: comment.bbsId,
        docNumber: comment.docNumber,
        reSeqno: comment.seqno,
        content: newContent,
        userId: comment.userId,
      );
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment(String commentId) async {
    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final initialLength = _mockComments.length;
      _mockComments.removeWhere((comment) => comment.id == commentId);
      return _mockComments.length < initialLength;
    } else {
      // 실제 API 호출 - CommentService 사용
      final comment = _commentCache[commentId];
      if (comment == null) {
        print('PostService.deleteComment: Comment not found in cache: $commentId');
        return false;
      }
      
      final success = await _commentService.deleteComment(
        bbsId: comment.bbsId,
        docNumber: comment.docNumber,
        reSeqno: comment.seqno,
        userId: comment.userId,
      );
      
      if (success) {
        _commentCache.remove(commentId);
      }
      
      return success;
    }
  }

  // 댓글 추가
  Future<Comment?> addComment(String postId, String content, {String? bbsId}) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    if (_isTestAccount) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        author: currentUser.name,
        content: content,
        createdAt: DateTime.now(),
        bbsId: bbsId ?? 'B0000111',
        docNumber: int.tryParse(postId) ?? 0,
        userId: currentUser.id,
        seqno: _mockComments.length + 1,
      );
      
      _mockComments.add(newComment);
      return newComment;
    } else {
      // 실제 API 호출 - CommentService 사용
      final actualBbsId = bbsId ?? 'B0000111';
      return await _commentService.createComment(
        bbsId: actualBbsId,
        docNumber: int.tryParse(postId) ?? 0,
        content: content,
      );
    }
  }
  
  // 전체 섹션 데이터 가져오기
  Future<Map<String, List<Post>>> getAllSectionPosts({int limit = 5}) async {
    print('PostService.getAllSectionPosts: START');
    print('PostService.getAllSectionPosts: currentUser = ${_authService.currentUser?.id}');
    print('PostService.getAllSectionPosts: isTestAccount = $_isTestAccount');
    
    if (_isTestAccount) {
      print('PostService.getAllSectionPosts: Using MOCK data');
      await Future.delayed(const Duration(milliseconds: 500));
      
      Map<String, List<Post>> sectionPosts = {};
      final sections = ['공지사항', '회사소식', '디지털에듀', '사우소식·자유게시판'];
      
      for (String section in sections) {
        final posts = _mockPosts
            .where((post) => post.section == section)
            .take(limit)
            .toList();
        sectionPosts[section] = posts;
        print('PostService.getAllSectionPosts: Mock section $section has ${posts.length} posts');
      }
      
      print('PostService.getAllSectionPosts: returning ${sectionPosts.length} sections of mock data');
      return sectionPosts;
    } else {
      print('PostService.getAllSectionPosts: Using REAL API');
      try {
        final result = await _apiService.getAllSectionPosts(limit: limit);
        print('PostService.getAllSectionPosts: API returned ${result.length} sections');
        result.forEach((section, posts) {
          print('PostService.getAllSectionPosts: API section $section has ${posts.length} posts');
        });
        return result;
      } catch (e) {
        print('PostService.getAllSectionPosts: API error - $e');
        return {};
      }
    }
  }
}