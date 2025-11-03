import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:streamsync_lite/core/di/injection.dart';
import 'package:streamsync_lite/data/local/database.dart';
import 'package:streamsync_lite/data/repositories/video_repository.dart';
import 'package:streamsync_lite/presentation/blocs/auth/auth_bloc.dart';
import 'package:streamsync_lite/presentation/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          _HomeFeedTab(),
          _FavoritesTab(),
          _LibraryTab(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_outlined), activeIcon: Icon(Icons.video_library), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['All', 'Trending', 'New', 'Popular'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((String category) => Tab(text: category)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((String category) {
              return _VideoGrid(key: PageStorageKey(category), category: category.toLowerCase());
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _VideoGrid extends StatefulWidget {
  final String category;
  const _VideoGrid({super.key, required this.category});

  @override
  State<_VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<_VideoGrid> {
  final VideoRepository _videoRepository = getIt<VideoRepository>();
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos(forceRefresh: true); // Always fetch fresh data on init
  }

  Future<void> _loadVideos({bool forceRefresh = false}) async {
    final categoryParam = widget.category.toLowerCase() == 'all' ? null : widget.category.toLowerCase();
    print('📱 Loading videos for category: ${categoryParam ?? "all"} (forceRefresh: $forceRefresh)');
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final videos = await _videoRepository.getLatestVideos(
        forceRefresh: forceRefresh,
        maxResults: 50,
        category: categoryParam,
      );
      print('✅ Loaded ${videos.length} videos for category: ${categoryParam ?? "all"}');
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return const Center(child: Text('No videos found.'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadVideos(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return _buildVideoCard(_videos[index]);
        },
      ),
    );
  }

  Widget _buildVideoCard(Video video) {
    return _VideoCard(video: video);
  }
}

// Reusable Video Card Widget
class _VideoCard extends StatelessWidget {
  final Video video;
  
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/video-player',
          arguments: {
            'videoId': video.videoId,
            'title': video.title,
            'description': video.description,
            'channelTitle': video.channelTitle,
            'viewCount': video.viewCount,
            'likeCount': video.likeCount,
            'commentCount': video.commentCount,
            'publishedAt': video.publishedAt.toIso8601String(),
          },
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 120,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(video.durationSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatCount(video.viewCount),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.comment_outlined, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatCount(video.commentCount),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _formatCount(BigInt? count) {
    if (count == null) return '0';
    final value = count.toInt();
    final formatter = NumberFormat.compact();
    return formatter.format(value);
  }
}

class _FavoritesTab extends StatefulWidget {
  const _FavoritesTab();

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Please login to see your favorites.'));
        }

        return FutureBuilder<List<Favorite>>(
          future: getIt<AppDatabase>().getAllFavorites(authState.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No favorites yet', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Videos you favorite will appear here', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            final favorites = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                // Fetch video details from database
                return FutureBuilder<Video?>(
                  future: getIt<AppDatabase>().getVideoById(favorite.videoId),
                  builder: (context, videoSnapshot) {
                    if (videoSnapshot.connectionState == ConnectionState.waiting) {
                      return const Card(child: Center(child: CircularProgressIndicator()));
                    }
                    if (!videoSnapshot.hasData || videoSnapshot.data == null) {
                      // Video not in local database, skip it
                      return const SizedBox.shrink();
                    }
                    final video = videoSnapshot.data!;
                    return _VideoCard(video: video);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LibraryTab extends StatefulWidget {
  const _LibraryTab();

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Please login to see your library.'));
        }

        return FutureBuilder<List<Video>>(
          future: getIt<AppDatabase>().getVideosWithProgress(authState.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No watch history found.'));
            }
            final videos = snapshot.data!;
            return ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text(video.title),
                  subtitle: Text(video.channelTitle),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/video-player',
                      arguments: {
                        'videoId': video.videoId,
                        'title': video.title,
                        'description': video.description,
                        'channelTitle': video.channelTitle,
                        'viewCount': video.viewCount,
                        'likeCount': video.likeCount,
                        'commentCount': video.commentCount,
                        'publishedAt': video.publishedAt.toIso8601String(),
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// Profile tab is now handled by the full ProfileScreen which includes Settings
