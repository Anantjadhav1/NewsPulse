import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article_model.dart';
import '../screens/article_detail_screen.dart';
import '../screens/playlists_screen.dart';
import '../services/bookmark_service.dart';
import '../services/like_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/gemini_service.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  const ArticleCard({super.key, required this.article});

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isDownloaded = false;

  // AI Summary
  String _aiSummary = '';
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _checkStatuses();
    _loadAiSummary();
  }

  void _checkStatuses() async {
    final liked = await LikeService().isLiked(widget.article.url);
    final downloaded =
        await DownloadService().isDownloaded(widget.article.url);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _isDownloaded = downloaded;
    });
  }

  // Load AI summary from Gemini
  void _loadAiSummary() async {
    try {
      final summary = await GeminiService().summarizeArticle(
        title: widget.article.title,
        description: widget.article.description,
        source: widget.article.source,
      );
      if (!mounted) return;
      setState(() {
        _aiSummary = summary;
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiSummary = widget.article.description;
        _isLoadingSummary = false;
      });
    }
  }

  void _toggleLike() async {
    final liked = await LikeService().toggleLike(widget.article.url);
    if (liked) {
      await LikeService().addInterestScore(widget.article.source);
    }
    if (!mounted) return;
    setState(() => _isLiked = liked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(liked ? 'Liked!' : 'Unliked'),
        backgroundColor:
            liked ? const Color(0xFFCC0000) : Colors.grey[800],
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleBookmark() async {
    await BookmarkService().saveBookmark(widget.article);
    if (!mounted) return;
    setState(() => _isBookmarked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmarked!'),
        backgroundColor: Color(0xFFCC0000),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleDownload() async {
    await DownloadService().downloadArticle(widget.article);
    if (!mounted) return;
    setState(() => _isDownloaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloaded for offline reading!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareArticle() {
    final String shareText =
        '📰 ${widget.article.title}\n\n'
        '${_aiSummary.isNotEmpty ? _aiSummary : widget.article.description}\n\n'
        '🔗 Read more: ${widget.article.url}\n\n'
        'Shared via NewsPulse';
    Share.share(shareText, subject: widget.article.title);
  }

  void _showPlaylistDialog() async {
    final playlists = await PlaylistService().getPlaylistNames();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('No playlists yet!',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PlaylistsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000)),
                    child: const Text('Create Playlist',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            ...playlists.map(
              (name) => ListTile(
                leading: const Icon(Icons.playlist_add,
                    color: Color(0xFFCC0000)),
                title: Text(name,
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await PlaylistService()
                      .addToPlaylist(name, widget.article);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to $name!'),
                      backgroundColor: const Color(0xFFCC0000),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Generate consistent color from source name
  Color _getSourceColor(String source) {
    final colors = [
      const Color(0xFFCC0000),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFE65100),
      const Color(0xFF4527A0),
      const Color(0xFF00695C),
    ];
    final index = source.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildPlaceholder() {
    final color = _getSourceColor(widget.article.source);
    final initial = widget.article.source.isNotEmpty
        ? widget.article.source[0].toUpperCase()
        : 'N';
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: -10,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.article.source,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'News Article',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ArticleDetailScreen(article: widget.article),
        ),
      ),
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or Placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: widget.article.urlToImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.article.urlToImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration:
                          const Duration(milliseconds: 200),
                      placeholder: (_, __) => Container(
                        height: 160,
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFCC0000)),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC0000)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFCC0000)
                                  .withOpacity(0.4)),
                        ),
                        child: Text(
                          widget.article.source,
                          style: const TextStyle(
                            color: Color(0xFFCC0000),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.article.publishedAt.length > 10
                            ? widget.article.publishedAt
                                .substring(0, 10)
                            : widget.article.publishedAt,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    widget.article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // AI Summary Section
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: Colors.blue, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI Summary',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'by Gemini',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Summary text or loading
                        _isLoadingSummary
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Generating summary...',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _aiSummary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        icon: _isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _isLiked
                            ? const Color(0xFFCC0000)
                            : Colors.grey,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _isBookmarked
                            ? const Color(0xFFCC0000)
                            : Colors.grey,
                        onTap: _toggleBookmark,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: _isDownloaded
                            ? Icons.download_done
                            : Icons.download_outlined,
                        color: _isDownloaded
                            ? Colors.green
                            : Colors.grey,
                        onTap: _toggleDownload,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.share,
                        color: Colors.grey,
                        onTap: _shareArticle,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.playlist_add,
                        color: Colors.grey,
                        onTap: _showPlaylistDialog,
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.grey, size: 14),
                    ],
                  ),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}