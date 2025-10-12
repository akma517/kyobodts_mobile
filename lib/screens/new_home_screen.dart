import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/push_message.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../themes/theme_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/content_modal.dart';
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
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
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
  
  void _testApiCall() async {
    try {
      final allSectionPosts = await _postService.getAllSectionPosts();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API 결과'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...allSectionPosts.entries.map((entry) => 
                      ExpansionTile(
                        title: Text('${entry.key} (${entry.value.length}개)'),
                        children: entry.value.map((post) => 
                          ListTile(
                            title: Text(
                              post.title,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '작성자: ${post.author}\nctid: ${post.ctid}, docNumber: ${post.docNumber}\n조회수: ${post.viewCount}, 댓글: ${post.commentCount}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            dense: true,
                          )
                        ).toList(),
                      )
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API 오류'),
            content: Text('오류: $e'),
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
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailScreen(
                                          postId: post.id,
                                          section: section,
                                        ),
                                      ),
                                    );
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
      floatingActionButton: kDebugMode ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "show_token",
            mini: true,
            onPressed: _showFCMToken,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.token),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "test_push",
            mini: true,
            onPressed: _testPushNotification,
            child: const Icon(Icons.notifications),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "test_api",
            mini: true,
            onPressed: _testApiCall,
            backgroundColor: Colors.green,
            child: const Icon(Icons.api),
          ),
        ],
      ) : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inMinutes}분 전';
    }
  }
}