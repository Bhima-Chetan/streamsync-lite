import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/di/injection.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String? title;
  final String? description;
  final String? channelTitle;
  final BigInt? viewCount;
  final BigInt? likeCount;
  final BigInt? commentCount;
  final DateTime? publishedAt;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.title,
    this.description,
    this.channelTitle,
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.publishedAt,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _isFavorite = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _showDescription = false;
  bool _isInitializing = true;
  Timer? _progressTimer;
  int _lastSavedPosition = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;

  @override
  void initState() {
    super.initState();

    // Check if video is already favorited
    _checkIfFavorited();
    
    // Load saved progress and resume
    _loadAndResumeProgress();
    
    // Load comments
    _loadComments();
  }
  
  Future<void> _loadAndResumeProgress() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _initializePlayer(0);
      return;
    }
    
    try {
      final database = getIt<AppDatabase>();
      final progress = await database.getProgress('${authState.userId}-${widget.videoId}');
      final startPosition = progress?.positionSeconds ?? 0;
      
      _initializePlayer(startPosition);
      
      // Start periodic progress saving
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _saveProgress();
      });
    } catch (e) {
      print('Error loading progress: $e');
      _initializePlayer(0);
    }
  }
  
  void _initializePlayer(int startPosition) {
    // Initialize YouTube player
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        startAt: startPosition,
      ),
    )..addListener(_onPlayerStateChange);
    
    setState(() => _isInitializing = false);
  }
  
  Future<void> _saveProgress() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final controller = _controller;
    if (controller == null || !controller.value.isReady) return;
    
    final position = controller.value.position.inSeconds;
    final duration = controller.metadata.duration.inSeconds;
    
    if (duration <= 0) return;
    
    // Only save if position changed significantly (avoid excessive writes)
    if ((position - _lastSavedPosition).abs() < 3) return;
    
    final completedPercent = ((position / duration) * 100).round();
    
    try {
      final videoRepository = getIt<VideoRepository>();
      await videoRepository.saveProgress(
        authState.userId,
        widget.videoId,
        position,
        completedPercent,
      );
      _lastSavedPosition = position;
      print('Progress saved: $position/$duration seconds ($completedPercent%)');
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void _onPlayerStateChange() {
    final controller = _controller;
    if (controller != null && controller.value.isReady && !_isPlayerReady) {
      setState(() => _isPlayerReady = true);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.getVideoComments(widget.videoId, 20);
      
      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response as List);
          _loadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress(); // Save one last time before disposing
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _checkIfFavorited() {
    // Check if this video is in favorites
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final favoritesState = context.read<FavoritesBloc>().state;
      if (favoritesState is FavoritesLoaded) {
        setState(() {
          _isFavorite = favoritesState.isFavorite(widget.videoId);
        });
      }
    }
  }

  void _toggleFavorite() {
    // Get user ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add favorites'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Toggle favorite in BLoC (this will update database)
    context.read<FavoritesBloc>().add(
          ToggleFavorite(authState.userId, widget.videoId),
        );

    // Update local UI state
    setState(() => _isFavorite = !_isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) _isDisliked = false;
    });
  }

  void _toggleDislike() {
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) _isLiked = false;
    });
  }

  void _shareVideo() {
    final String videoUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    final String shareText = '${widget.title ?? "Check out this video"}\n\n$videoUrl';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () async {
                // Copy to clipboard
                await Clipboard.setData(ClipboardData(text: videoUrl));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Copy Title & Link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Text copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isInitializing || _controller == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // YouTube Player
                  YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: theme.colorScheme.primary,
                    progressColors: ProgressBarColors(
                      playedColor: theme.colorScheme.primary,
                      handleColor: theme.colorScheme.primary,
                    ),
                    onReady: () {
                      setState(() => _isPlayerReady = true);
                    },
                    onEnded: (data) {
                      // TODO: Mark video as completed in database
                      _showRelatedVideos();
                    },
                  ),

            // Video Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // Video Title & Actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? 'Video Title',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatViewCount(widget.viewCount)} views${widget.publishedAt != null ? ' • ${_getTimeAgo(widget.publishedAt!)}' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: _isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          label: _formatCount(widget.likeCount),
                          onTap: _toggleLike,
                          isActive: _isLiked,
                        ),
                        _buildActionButton(
                          icon: _isDisliked
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          label: 'Dislike',
                          onTap: _toggleDislike,
                          isActive: _isDisliked,
                        ),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: _shareVideo,
                        ),
                        _buildActionButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          label: 'Save',
                          onTap: _toggleFavorite,
                          isActive: _isFavorite,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Channel Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.channelTitle ?? 'Channel Name',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatCount(widget.viewCount) + ' views',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Subscribe feature coming soon')),
                            );
                          },
                          child: const Text('Subscribe'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => setState(
                              () => _showDescription = !_showDescription),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.description ??
                                      'This is a sample video description. Learn more about this amazing content...',
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: _showDescription ? null : 3,
                                  overflow: _showDescription
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _showDescription ? 'Show less' : 'Show more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 32),

                  // Comments Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Comments',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${widget.commentCount != null ? _formatCount(widget.commentCount) : '0'})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_loadingComments)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_comments.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'No comments available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._comments.take(5).map((comment) {
                            final publishedAt = DateTime.parse(comment['publishedAt']);
                            final timeAgo = _getTimeAgo(publishedAt);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(
                                      comment['authorProfileImageUrl'] ?? '',
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                    child: comment['authorProfileImageUrl'] == null
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment['authorName'] ?? 'Unknown',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              timeAgo,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment['text'] ?? '',
                                          style: theme.textTheme.bodyMedium,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (comment['likeCount'] != null && comment['likeCount'] > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.thumb_up_outlined,
                                                  size: 14,
                                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  comment['likeCount'].toString(),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        if (_comments.length > 5)
                          TextButton(
                            onPressed: () {
                              // Show all comments in a bottom sheet
                            },
                            child: const Text('Show more comments'),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Related Videos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Related Videos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._buildRelatedVideos(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRelatedVideos() {
    return List.generate(3, (index) {
      final theme = Theme.of(context);
      return InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoId: 'dQw4w9WgXcQ', // Sample video ID
                title: 'Related Video ${index + 1}',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 160,
                height: 90,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 32,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '10:23',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Video Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Related Video Title ${index + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.channelTitle ?? 'Channel Name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${(index + 1) * 100}K views • ${index + 1} days ago',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showRelatedVideos() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Video Ended',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Watch more videos below'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Watching'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(BigInt? count) {
    if (count == null) return '0';
    final value = count.toInt();
    final formatter = NumberFormat.compact();
    return formatter.format(value);
  }

  String _formatViewCount(BigInt? viewCount) {
    if (viewCount == null) return '0';
    
    final count = viewCount.toInt();
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
