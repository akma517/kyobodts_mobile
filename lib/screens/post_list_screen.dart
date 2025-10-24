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
  final ScrollController _scrollController = ScrollController();
  List<PostListItem> posts = [];
  List<PostListItem> filteredPosts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  String searchType = '제목';
  final List<String> searchTypes = ['제목', '제목+내용', '게시자'];
  String searchCondition = 'docSubject';
  String searchString = '';

  @override
  void initState() {
    super.initState();
    print('PostListScreen.initState: Initializing for section "${widget.section}"');
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent - 200;
    
    print('_onScroll: pixels=${position.pixels.toInt()}, maxExtent=${position.maxScrollExtent.toInt()}, threshold=${threshold.toInt()}');
    print('_onScroll: isLoadingMore=$isLoadingMore, hasMoreData=$hasMoreData, searchString=$searchString');
    
    if (position.pixels >= threshold) {
      if (!isLoadingMore && hasMoreData) {
        print('_onScroll: Triggering _loadMorePosts()');
        _loadMorePosts();
      }
    }
  }

  void _loadPosts() async {
    print('=== PostListScreen._loadPosts START ===');
    print('PostListScreen._loadPosts: section = "${widget.section}"');
    print('PostListScreen._loadPosts: isTestAccount = ${_authService.isTestAccount}');
    print('PostListScreen._loadPosts: currentUser = ${_authService.currentUser?.id}');
    
    if (mounted) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
      });
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
        loadedPosts = await _apiService.getSectionPosts(widget.section, page: currentPage, limit: 10, searchCondition: searchCondition, searchString: searchString);
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
        hasMoreData = loadedPosts.length >= 10;
      });
      print('PostListScreen._loadPosts: State updated - posts: ${posts.length}, isLoading: false');
    } else {
      print('PostListScreen._loadPosts: Widget not mounted, skipping state update');
    }
    
    print('=== PostListScreen._loadPosts END ===');
  }

  void _loadMorePosts() async {
    if (isLoadingMore || !hasMoreData) return;
    
    print('=== PostListScreen._loadMorePosts START ===');
    print('PostListScreen._loadMorePosts: currentPage = $currentPage');
    
    if (mounted) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
    }
    
    List<PostListItem> newPosts = [];
    
    if (_authService.isTestAccount) {
      print('PostListScreen._loadMorePosts: Using MOCK data');
      await Future.delayed(const Duration(milliseconds: 500));
      newPosts = _getMockPostsForPage(currentPage);
    } else {
      print('PostListScreen._loadMorePosts: Calling REAL API for page $currentPage');
      try {
        newPosts = await _apiService.getSectionPosts(widget.section, page: currentPage, limit: 10, searchCondition: searchCondition, searchString: searchString);
        print('PostListScreen._loadMorePosts: API call completed - ${newPosts.length} new posts received');
      } catch (e) {
        print('PostListScreen._loadMorePosts: API call failed - $e');
        newPosts = [];
      }
    }
    
    if (mounted) {
      setState(() {
        if (newPosts.isNotEmpty) {
          posts.addAll(newPosts);
          filteredPosts = posts;
        }
        hasMoreData = newPosts.length >= 10 || (_authService.isTestAccount && currentPage < 3);
        isLoadingMore = false;
      });
      print('PostListScreen._loadMorePosts: State updated - total posts: ${posts.length}, hasMoreData: $hasMoreData');
    }
    
    print('=== PostListScreen._loadMorePosts END ===');
  }
  
  List<PostListItem> _getMockPosts() {
    return _getMockPostsForPage(1);
  }
  
  List<PostListItem> _getMockPostsForPage(int page, [int count = 10]) {
    final baseNumber = 13000 - ((page - 1) * count);
    final baseDate = DateTime.now().subtract(Duration(days: (page - 1) * 7));
    
    return List.generate(count, (index) {
      final docNumber = baseNumber - index;
      final date = baseDate.subtract(Duration(days: index));
      final formattedDate = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      final hasFiles = (index % 3 == 0); // 3개 중 1개는 첨부파일 있음
      
      return PostListItem(
        rownumber: ((page - 1) * count) + index + 1,
        ctid: 321,
        bbsId: 'B0000111',
        docNumber: docNumber,
        docSubject: 'Mock 게시글 $docNumber - 페이지 $page',
        docRefCnt: 50 + (index * 5),
        docRegdate: formattedDate,
        userName: ['관리자', '교육팀', '개발팀', '기획팀'][index % 4],
        replayCt: index % 10,
        docText: 'Mock 게시글 내용입니다. 페이지 $page의 $index번째 게시글입니다.',
        fileCnt: hasFiles ? (index % 3 + 1) : 0, // 첨부파일 개수 1-3개
      );
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    
    setState(() {
      searchString = query;
      currentPage = 1;
      hasMoreData = true;
    });
    
    _loadPosts();
  }
  
  void _updateSearchCondition(String newSearchType) {
    setState(() {
      searchType = newSearchType;
      switch (newSearchType) {
        case '제목':
          searchCondition = 'docSubject';
          break;
        case '제목+내용':
          searchCondition = 'docText';
          break;
        case '게시자':
          searchCondition = 'userName';
          break;
      }
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
                        _updateSearchCondition(value!);
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
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('검색'),
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
                            _searchController.clear();
                            setState(() {
                              searchString = '';
                              currentPage = 1;
                              hasMoreData = true;
                            });
                            return _loadPosts();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredPosts.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredPosts.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
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
                                          if (post.hasAttachment) ...[
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
                                                    Icons.attach_file,
                                                    size: 12,
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${post.fileCnt}',
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
                                        post: post.toPost(widget.section),
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
    _scrollController.dispose();
    super.dispose();
  }
}