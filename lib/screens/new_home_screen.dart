import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/push_message.dart';
import '../services/post_service.dart';
import '../services/post_list_api_service.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../themes/theme_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/content_modal.dart';
import '../widgets/webview_modal.dart';
import '../utils/push_test_helper.dart';
import '../widgets/common_app_bar.dart';
import 'post_list_screen.dart';
import 'post_detail_screen.dart';
import 'login_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final PostService _postService = PostService();
  final PostListApiService _postListApiService = PostListApiService();
  final AuthService _authService = AuthService();
  final List<String> sections = ['공지사항', '회사소식', '디지털에듀', '사우소식·자유게시판'];
  Map<String, List<Post>> sectionPosts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() async {
    print('NewHomeScreen._loadPosts: START');
    if (mounted) {
      setState(() => isLoading = true);
    }
    
    print('NewHomeScreen._loadPosts: Calling PostService.getAllSectionPosts()');
    final allSectionPosts = await _postService.getAllSectionPosts();
    print('NewHomeScreen._loadPosts: Received ${allSectionPosts.length} sections');
    
    if (!mounted) {
      print('NewHomeScreen._loadPosts: Widget not mounted, returning');
      return;
    }
    
    if (mounted) {
      setState(() {
        sectionPosts = allSectionPosts;
        isLoading = false;
      });
      print('NewHomeScreen._loadPosts: State updated, isLoading = false');
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeType.values.map((theme) {
            return ListTile(
              title: Text(AppTheme.getThemeName(theme)),
              onTap: () {
                context.read<ThemeProvider>().setTheme(theme);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _logout() async {
    print('NewHomeScreen._logout: Starting logout process');
    try {
      await _authService.logout();
      print('NewHomeScreen._logout: AuthService logout completed');
    } catch (e) {
      print('NewHomeScreen._logout: AuthService logout error: $e');
    } finally {
      print('NewHomeScreen._logout: Navigating to login screen');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    
    print('🔥 저장된 FCM 토큰: $token');
    print('🔥 SharedPreferences 키들: ${prefs.getKeys()}');
    
    final displayToken = token?.isNotEmpty == true ? token! : '토큰이 없습니다\n\nFirebase 초기화가 완료되지 않았거나\n토큰 생성에 실패했습니다.';
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM 토큰'),
          content: SelectableText(displayToken),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  void _testPushNotification() async {
    final data = PushTestHelper.getSamplePushData();
    final message = PushMessage.fromMap(data);
    
    if (message.hasContent) {
      ContentType contentType;
      switch (message.contentTypeEnum) {
        case 'pdf':
          contentType = ContentType.pdf;
          break;
        case 'asset':
          contentType = ContentType.asset;
          break;
        default:
          contentType = ContentType.html;
      }

      ContentModalHelper.showContentModal(
        context,
        contentUrl: message.contentUrl!,
        title: message.title,
        contentType: contentType,
      );
    }
  }
  
  void _openGroupwareNews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WebViewModal(
          url: 'http://54.206.1.146:5001/summary',
          title: '',
        ),
        fullscreenDialog: true,
      ),
    );
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '교보DTS',
        showBackButton: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadPosts(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    ],
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final posts = sectionPosts[section] ?? [];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  section,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostListScreen(section: section),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '더보기',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (posts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  '게시글이 없습니다.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...posts.asMap().entries.map((entry) {
                              final post = entry.value;
                              final isLast = entry.key == posts.length - 1;
                              return Container(
                                decoration: BoxDecoration(
                                  border: !isLast ? Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ) : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  title: Text(
                                    post.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          post.author,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(post.createdAt),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.commentCount}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (post.hasAttachment) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.attach_file,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  onTap: () async {
                                    await _navigateToPostDetail(post, section);
                                  },
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Future<void> _navigateToPostDetail(Post homePost, String section) async {
    print('=== NewHomeScreen._navigateToPostDetail START ===');
    print('클릭한 게시글: ${homePost.title}');
    print('섹션: $section');
    print('게시글 CTID: ${homePost.ctid}');
    
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // 사우소식·자유게시판 섹션의 경우 CTID로 정확한 섹션 결정
      String targetSection = section;
      if (section == '사우소식·자유게시판') {
        targetSection = _getSectionByCtid(homePost.ctid);
        print('사우소식·자유게시판 섹션 매핑: CTID ${homePost.ctid} -> $targetSection');
      }
      
      // 해당 섹션의 상세 게시글 목록 가져오기
      print('섹션별 API 호출 시작: $targetSection');
      final sectionPostItems = await _postListApiService.getSectionPosts(targetSection);
      final sectionPosts = sectionPostItems.map((item) => item.toPost(targetSection)).toList();
      print('섹션별 API 결과: ${sectionPosts.length}개 게시글');
      
      if (sectionPosts.isEmpty) {
        print('⚠️ 섹션별 API가 빈 결과를 반환했습니다!');
        print('⚠️ 가능한 원인:');
        print('   1. 로그인 세션 만료');
        print('   2. 해당 섹션에 게시글이 없음');
        print('   3. API 엔드포인트 오류');
      } else {
        print('✅ 섹션별 API 성공: ${sectionPosts.length}개 게시글 받음');
        for (int i = 0; i < sectionPosts.length && i < 3; i++) {
          print('   [$i] ${sectionPosts[i].title}');
        }
      }
      
      // 제목으로 매칭되는 게시글 찾기 (docSubject가 title로 매핑됨)
      final homePostCleanTitle = _cleanTitle(homePost.title);
      print('홈 게시글 원본 제목: "${homePost.title}"');
      print('홈 게시글 정제된 제목: "$homePostCleanTitle"');
      
      Post? matchedPost;
      for (int i = 0; i < sectionPosts.length; i++) {
        final sectionPost = sectionPosts[i];
        final sectionPostCleanTitle = _cleanTitle(sectionPost.title);
        
        print('[$i] 원본 제목 (docSubject): "${sectionPost.title}"');
        print('[$i] 정제된 제목: "$sectionPostCleanTitle"');
        print('[$i] 비교 결과: ${homePostCleanTitle == sectionPostCleanTitle ? "매칭 성공!" : "매칭 실패"}');
        
        if (homePostCleanTitle == sectionPostCleanTitle) {
          matchedPost = sectionPost;
          print('✅ 최종 매칭 성공! 인덱스: $i');
          print('✅ 매칭된 게시글 내용 길이: ${sectionPost.content.length}');
          break;
        }
      }
      
      if (matchedPost == null) {
        print('❌ 매칭되는 게시글을 찾지 못함');
        print('❌ 총 ${sectionPosts.length}개 게시글 중 매칭 실패');
      }
      
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (matchedPost != null) {
        print('상세 데이터로 이동: content length = ${matchedPost.content.length}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: matchedPost!,
              ),
            ),
          );
        }
      } else {
        print('매칭되는 게시글을 찾지 못함, 기존 데이터로 이동');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: homePost,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('섹션별 API 호출 실패: $e');
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(context);
      }
      // 기존 데이터로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: homePost,
            ),
          ),
        );
      }
    }
    
    print('=== NewHomeScreen._navigateToPostDetail END ===');
  }

  String _getSectionByCtid(int ctid) {
    switch (ctid) {
      case 321:
        return '공지사항';
      case 172:
        return '회사소식';
      case 164:
        return '사우소식';
      case 20:
        return '자유게시판';
      case 313:
        return '디지털에듀';
      default:
        return '기타';
    }
  }

  String _cleanTitle(String title) {
    // 1. 대소문자를 대문자로 변환
    // 2. 모든 공백 문자 제거 (일반 공백, 탭, 줄바꿈 등)
    return title
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ''); // 모든 공백 제거
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}