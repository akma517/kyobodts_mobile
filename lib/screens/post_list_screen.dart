import 'package:flutter/material.dart';
import '../models/post_list_item.dart';
import '../services/post_list_api_service.dart';
import '../services/auth_service.dart';
import 'post_detail_screen.dart';
import '../widgets/common_app_bar.dart';

class PostListScreen extends StatefulWidget {
  final String section;

  const PostListScreen({super.key, required this.section});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final PostListApiService _apiService = PostListApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<PostListItem> posts = [];
  List<PostListItem> filteredPosts = [];
  bool isLoading = true;
  String searchType = '제목';
  final List<String> searchTypes = ['제목', '제목+내용', '게시자'];

  @override
  void initState() {
    super.initState();
    print('PostListScreen.initState: Initializing for section "${widget.section}"');
    _loadPosts();
  }

  void _loadPosts() async {
    print('=== PostListScreen._loadPosts START ===');
    print('PostListScreen._loadPosts: section = "${widget.section}"');
    print('PostListScreen._loadPosts: isTestAccount = ${_authService.isTestAccount}');
    print('PostListScreen._loadPosts: currentUser = ${_authService.currentUser?.id}');
    
    if (mounted) {
      setState(() => isLoading = true);
      print('PostListScreen._loadPosts: Loading state set to true');
    }
    
    List<PostListItem> loadedPosts = [];
    final startTime = DateTime.now();
    
    if (_authService.isTestAccount) {
      print('PostListScreen._loadPosts: Using MOCK data');
      await Future.delayed(const Duration(milliseconds: 500));
      loadedPosts = _getMockPosts();
      print('PostListScreen._loadPosts: Mock data loaded - ${loadedPosts.length} posts');
    } else {
      print('PostListScreen._loadPosts: Calling REAL API');
      try {
        loadedPosts = await _apiService.getSectionPosts(widget.section);
        print('PostListScreen._loadPosts: API call completed - ${loadedPosts.length} posts received');
      } catch (e) {
        print('PostListScreen._loadPosts: API call failed - $e');
        loadedPosts = [];
      }
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    print('PostListScreen._loadPosts: Data loading took ${duration}ms');
    
    if (mounted) {
      setState(() {
        posts = loadedPosts;
        filteredPosts = loadedPosts;
        isLoading = false;
      });
      print('PostListScreen._loadPosts: State updated - posts: ${posts.length}, isLoading: false');
    } else {
      print('PostListScreen._loadPosts: Widget not mounted, skipping state update');
    }
    
    print('=== PostListScreen._loadPosts END ===');
  }
  
  List<PostListItem> _getMockPosts() {
    return [
      PostListItem(
        rownumber: 1,
        ctid: 321,
        bbsId: 'B0000111',
        docNumber: 12902,
        docSubject: '2024년 신년 인사',
        docRefCnt: 150,
        docRegDate: '2025-01-15',
        userName: '대표이사',
        replayCt: 5,
      ),
      PostListItem(
        rownumber: 2,
        ctid: 313,
        bbsId: 'B0000039',
        docNumber: 12901,
        docSubject: '디지털 전환 교육 안내',
        docRefCnt: 89,
        docRegDate: '2025-01-14',
        userName: '교육팀',
        replayCt: 12,
      ),
    ];
  }

  void _searchPosts(String query) {
    if (!mounted) return;
    
    if (query.isEmpty) {
      setState(() => filteredPosts = posts);
      return;
    }

    setState(() {
      filteredPosts = posts.where((post) {
        switch (searchType) {
          case '제목':
            return post.docSubject.toLowerCase().contains(query.toLowerCase());
          case '제목+내용':
            return post.docSubject.toLowerCase().contains(query.toLowerCase());
          case '게시자':
            return post.userName.toLowerCase().contains(query.toLowerCase());
          default:
            return false;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('PostListScreen.build: Rendering for section "${widget.section}", isLoading: $isLoading, posts: ${posts.length}, filteredPosts: ${filteredPosts.length}');
    
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.section,
      ),
      body: Container(
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
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
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
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: searchType,
                      underline: const SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: searchTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => searchType = value!);
                        _searchPosts(_searchController.text);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '검색어를 입력하세요',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: _searchPosts,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPosts.isEmpty
                      ? const Center(child: Text('게시글이 없습니다.'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            print('PostListScreen: Pull-to-refresh triggered');
                            return _loadPosts();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  post.docSubject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            post.userName,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            post.formattedDate,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.visibility,
                                                  size: 12,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${post.docRefCnt}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 12,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${post.replayCt}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
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
                                        postId: post.docNumber.toString(),
                                        section: widget.section,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}