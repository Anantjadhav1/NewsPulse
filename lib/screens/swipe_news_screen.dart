import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/bookmark_service.dart';
import '../services/like_service.dart';
import 'article_detail_screen.dart';

class SwipeNewsScreen extends StatefulWidget {
  final List<Article> articles;
  const SwipeNewsScreen({super.key, required this.articles});

  @override
  State<SwipeNewsScreen> createState() => _SwipeNewsScreenState();
}

class _SwipeNewsScreenState extends State<SwipeNewsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, bool> _likedMap = {};
  final Map<int, bool> _bookmarkedMap = {};

  late List<Article> _articles;
  bool _isLoadingMore = false;

  final List<String> _categories = [
    'technology', 'sports', 'business',
    'entertainment', 'health', 'science', 'general',
  ];
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _articles = List.from(widget.articles);
    if (_articles.length < 5) _loadMore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _preloadImages(int fromIndex) {
    for (int i = fromIndex; i < fromIndex + 3 && i < _articles.length; i++) {
      if (_articles[i].urlToImage.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(_articles[i].urlToImage),
          context,
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final category = _categories[_categoryIndex % _categories.length];
      _categoryIndex++;
      final more = await ApiService().fetchByCategory(category);
      if (!mounted) return;
      setState(() {
        final existingUrls = _articles.map((a) => a.url).toSet();
        final newOnes =
            more.where((a) => !existingUrls.contains(a.url)).toList();
        _articles.addAll(newOnes);
        _isLoadingMore = false;
      });
      _preloadImages(_articles.length - more.length);
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _preloadImages(index + 1);
    if (index >= _articles.length - 5) _loadMore();
  }

  void _toggleLike(int index) async {
    final article = _articles[index];
    final liked = await LikeService().toggleLike(article.url);
    if (liked) await LikeService().addInterestScore(article.source);
    if (!mounted) return;
    setState(() => _likedMap[index] = liked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(liked ? 'Liked!' : 'Unliked'),
        backgroundColor:
            liked ? const Color(0xFFCC0000) : Colors.grey[800],
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleBookmark(int index) async {
    final article = _articles[index];
    await BookmarkService().saveBookmark(article);
    if (!mounted) return;
    setState(() => _bookmarkedMap[index] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmarked!'),
        backgroundColor: Color(0xFFCC0000),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareArticle(Article article) {
    final String shareText =
        '📰 ${article.title}\n\n'
        '${article.description}\n\n'
        '🔗 Read more: ${article.url}\n\n'
        'Shared via NewsPulse';
    Share.share(shareText, subject: article.title);
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

  // Smart placeholder for swipe screen
  Widget _buildSwipePlaceholder(Article article) {
    final color = _getSourceColor(article.source);
    final initial = article.source.isNotEmpty
        ? article.source[0].toUpperCase()
        : 'N';
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.6),
                  Colors.black,
                ],
              ),
            ),
          ),
          // Big faded letter
          Positioned(
            right: -20,
            top: 60,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 300,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Center icon + source
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withOpacity(0.6), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  article.source,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'News Article',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13),
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
    if (_articles.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _articles.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) =>
                _buildNewsPage(_articles[index], index),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'NewsPulse',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_articles.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Swipe hint
          if (_currentIndex == 0)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up,
                      color: Colors.white54, size: 32),
                  Text('Swipe up for next',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoadingMore)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Color(0xFFCC0000),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Loading more...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsPage(Article article, int index) {
    final isLiked = _likedMap[index] ?? false;
    final isBookmarked = _bookmarkedMap[index] ?? false;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image OR smart placeholder
          article.urlToImage.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: article.urlToImage,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFCC0000),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  // Image fails → show smart placeholder
                  errorWidget: (_, __, ___) =>
                      _buildSwipePlaceholder(article),
                )
              // No image URL → show smart placeholder
              : _buildSwipePlaceholder(article),

          // Gradient overlay (only when image exists)
          if (article.urlToImage.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black45,
                    Colors.black87,
                    Colors.black,
                  ],
                  stops: [0.2, 0.5, 0.75, 1.0],
                ),
              ),
            ),

          // Always show bottom gradient for text readability
          if (article.urlToImage.isEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            ),

          // Content
          Positioned(
            bottom: 40,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC0000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.source,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  article.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ArticleDetailScreen(article: article),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Read Full Article',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            )),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward,
                            size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Positioned(
            bottom: 60,
            right: 12,
            child: Column(
              children: [
                _buildSideButton(
                  icon: isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isLiked
                      ? const Color(0xFFCC0000)
                      : Colors.white,
                  label: 'Like',
                  onTap: () => _toggleLike(index),
                ),
                const SizedBox(height: 20),
                _buildSideButton(
                  icon: isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: isBookmarked
                      ? const Color(0xFFCC0000)
                      : Colors.white,
                  label: 'Save',
                  onTap: () => _toggleBookmark(index),
                ),
                const SizedBox(height: 20),
                _buildSideButton(
                  icon: Icons.share,
                  color: Colors.white,
                  label: 'Share',
                  onTap: () => _shareArticle(article),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}