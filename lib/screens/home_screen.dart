import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/article_card.dart';
import 'bookmarks_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'swipe_news_screen.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Article> _articles = [];
  List<Article> _top10 = [];
  List<Article> _liveArticles = [];
  bool _isLoading = true;
  bool _isTop10Loading = true;
  bool _isLiveLoading = true;
  String _selectedCategory = 'general';
  List<String> _userInterests = [];
  int _carouselIndex = 0;
  Timer? _carouselTimer;
  final PageController _carouselController = PageController();

  final List<Map<String, String>> _categories = [
    {'label': 'For You', 'query': 'general'},
    {'label': '🔥 Trending', 'query': 'general'},
    {'label': '💼 Business', 'query': 'business'},
    {'label': '💻 Technology', 'query': 'technology'},
    {'label': '🏏 Sports', 'query': 'sports'},
    {'label': '💪 Health', 'query': 'health'},
    {'label': '🎬 Entertainment', 'query': 'entertainment'},
    {'label': '🚀 Science', 'query': 'science'},
    {'label': '🌍 World', 'query': 'general'},
    {'label': '📈 Business', 'query': 'business'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
    _loadTop10();
    _loadLiveNews();
    _loadNews('general');
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_top10.isNotEmpty) {
        _carouselIndex = (_carouselIndex + 1) % _top10.length;
        if (_carouselController.hasClients) {
          _carouselController.animateToPage(
            _carouselIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _loadUserInterests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userInterests = prefs.getStringList('interests') ?? [];
    });
  }

  void _loadTop10() async {
    setState(() => _isTop10Loading = true);
    try {
      final articles = await ApiService().fetchTop10Headlines();
      setState(() {
        _top10 = articles;
        _isTop10Loading = false;
      });
    } catch (e) {
      setState(() => _isTop10Loading = false);
    }
  }

  void _loadLiveNews() async {
    setState(() => _isLiveLoading = true);
    try {
      final articles = await ApiService().fetchByCategory('general');
      setState(() {
        _liveArticles = articles.take(5).toList();
        _isLiveLoading = false;
      });
    } catch (e) {
      setState(() => _isLiveLoading = false);
    }
  }

  void _loadNews(String query) async {
    setState(() => _isLoading = true);
    try {
      List<Article> articles =
          await ApiService().fetchByCategory(query);
      setState(() {
        _articles = articles;
        _isLoading = false;
        _selectedCategory = query;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading news: $e')),
      );
    }
  }

  void _logout() async {
    await AuthService().logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          '📰 NewsApp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Color(0xFFCC0000)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFCC0000),
        onRefresh: () async {
          _loadNews(_selectedCategory);
          _loadTop10();
          _loadLiveNews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Auto Rotating Carousel ──
              _buildCarousel(),

              const SizedBox(height: 16),

              // ── Live Section ──
              _buildLiveSection(),

              const SizedBox(height: 16),

              // ── Your Interests Section ──
              if (_userInterests.isNotEmpty) _buildInterestsSection(),

              const SizedBox(height: 16),

              // ── Category chips ──
              _buildCategoryChips(),

              const SizedBox(height: 12),

              // ── News List ──
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFCC0000),
                        ),
                      ),
                    )
                  : _articles.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'No articles found!',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _articles.length,
                          itemBuilder: (context, index) =>
                              ArticleCard(article: _articles[index]),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carousel Widget ──
  Widget _buildCarousel() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A1A),
      ),
      child: _isTop10Loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFCC0000)))
          : Stack(
              children: [
                // Pages
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PageView.builder(
                    controller: _carouselController,
                    itemCount: _top10.length,
                    onPageChanged: (i) =>
                        setState(() => _carouselIndex = i),
                    itemBuilder: (context, index) {
                      final article = _top10[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SwipeNewsScreen(articles: _top10),
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            article.urlToImage.isNotEmpty
                                ? Image.network(
                                    article.urlToImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                          color:
                                              const Color(0xFF2A2A2A),
                                          child: const Icon(
                                              Icons.newspaper,
                                              color: Colors.grey,
                                              size: 60),
                                        ),
                                  )
                                : Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: const Icon(Icons.newspaper,
                                        color: Colors.grey, size: 60),
                                  ),
                            // Gradient
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                  stops: [0.4, 1.0],
                                ),
                              ),
                            ),
                            // Number badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCC0000),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#${index + 1} Top Story',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // Title
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Dot indicators
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Row(
                    children: List.generate(
                      _top10.length > 10 ? 10 : _top10.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(left: 4),
                        width: _carouselIndex == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _carouselIndex == i
                              ? const Color(0xFFCC0000)
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Live Section Widget ──
  Widget _buildLiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC0000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Breaking & Live Updates',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _isLiveLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFCC0000)))
            : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _liveArticles.length,
                  itemBuilder: (context, index) {
                    final article = _liveArticles[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArticleDetailScreen(article: article),
                        ),
                      ),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFCC0000)
                                  .withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCC0000),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  article.source,
                                  style: const TextStyle(
                                    color: Color(0xFFCC0000),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // ── Interests Section Widget ──
  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '🎯 Based on Your Interests',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _userInterests.length,
            itemBuilder: (context, index) {
              final interest = _userInterests[index];
              return GestureDetector(
                onTap: () => _loadNews(interest),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory == interest
                        ? const Color(0xFFCC0000)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory == interest
                          ? const Color(0xFFCC0000)
                          : Colors.grey.shade800,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: _selectedCategory == interest
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Category Chips Widget ──
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['query'];
          return GestureDetector(
            onTap: () => _loadNews(cat['query']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCC0000)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFCC0000)
                      : Colors.grey.shade800,
                ),
              ),
              child: Text(
                cat['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}