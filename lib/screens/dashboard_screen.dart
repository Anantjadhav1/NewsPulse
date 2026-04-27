import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/bookmark_service.dart';
import 'article_detail_screen.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'swipe_news_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Article> _top10 = [];
  List<Article> _liveArticles = [];
  bool _isTop10Loading = true;
  bool _isLiveLoading = true;
  int _carouselIndex = 0;
  Timer? _carouselTimer;
  final PageController _carouselController = PageController();

  // Sensex data
  String _sensexValue = 'Loading...';
  String _sensexChange = '';
  bool _sensexUp = true;
  bool _sensexLoading = true;

  // Cricket data
  List<Map<String, String>> _matches = [];
  bool _cricketLoading = true;

  // Bookmark and download counts
  int _bookmarkCount = 0;
  int _downloadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTop10();
    _loadLiveNews();
    _loadSensex();
    _loadCricket();
    _loadCounts();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
      if (_top10.isNotEmpty && _carouselController.hasClients) {
        _carouselIndex = (_carouselIndex + 1) % _top10.length;
        _carouselController.animateToPage(
          _carouselIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadTop10() async {
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
    try {
      final articles = await ApiService().searchNews('breaking news live');
      setState(() {
        _liveArticles = articles.take(5).toList();
        _isLiveLoading = false;
      });
    } catch (e) {
      setState(() => _isLiveLoading = false);
    }
  }

  void _loadSensex() async {
    try {
      // Using Yahoo Finance API for Sensex (BSE)
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/%5EBSESN?interval=1d&range=1d');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final price = meta['regularMarketPrice'];
        final prevClose = meta['chartPreviousClose'];
        final change = price - prevClose;
        final changePct = (change / prevClose) * 100;
        setState(() {
          _sensexValue = price.toStringAsFixed(2);
          _sensexChange =
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePct.toStringAsFixed(2)}%)';
          _sensexUp = change >= 0;
          _sensexLoading = false;
        });
      } else {
        setState(() {
          _sensexValue = 'Unavailable';
          _sensexLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sensexValue = 'Unavailable';
        _sensexLoading = false;
      });
    }
  }

  void _loadCricket() async {
    try {
      // Using cricbuzz free API via RapidAPI alternative
      final url = Uri.parse(
          'https://api.cricapi.com/v1/currentMatches?apikey=YOUR_CRICAPI_KEY&offset=0');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['data'] as List;
        setState(() {
          _matches = matches.take(3).map<Map<String, String>>((m) {
            return {
              'name': m['name']?.toString() ?? 'Match',
              'status': m['status']?.toString() ?? '',
              'score': m['score'] != null
                  ? (m['score'] as List)
                      .map((s) =>
                          '${s['r']}/${s['w']} (${s['o']} ov)')
                      .join(' | ')
                  : 'Score unavailable',
            };
          }).toList();
          _cricketLoading = false;
        });
      } else {
        _loadDummyCricket();
      }
    } catch (e) {
      _loadDummyCricket();
    }
  }

  void _loadDummyCricket() {
    setState(() {
      _matches = [
        {
          'name': 'IND vs AUS • Test',
          'status': 'Live',
          'score': 'IND: 287/4 (72.3 ov) | AUS: 310/8',
        },
        {
          'name': 'MI vs CSK • IPL 2025',
          'status': 'Upcoming',
          'score': 'Match starts at 7:30 PM IST',
        },
      ];
      _cricketLoading = false;
    });
  }

  void _loadCounts() async {
    final bookmarks = await BookmarkService().getBookmarks();
    final downloads = await DownloadService().getDownloadCount();
    setState(() {
      _bookmarkCount = bookmarks.length;
      _downloadCount = downloads;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Text(
                  '📊 Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              // ── Sensex Section ──
              _buildSensex(),

              const SizedBox(height: 16),

              // ── Top 10 Carousel ──
              _buildTop10Carousel(),

              const SizedBox(height: 16),

              // ── Cricket Scores ──
              _buildCricketSection(),

              const SizedBox(height: 16),

              // ── Live Section ──
              _buildLiveSection(),

              const SizedBox(height: 16),

              // ── Quick Access ──
              _buildQuickAccess(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sensex Widget ──
  Widget _buildSensex() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart,
                      color: Color(0xFFCC0000), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'SENSEX (BSE)',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _sensexLoading
                  ? const CircularProgressIndicator(
                      color: Color(0xFFCC0000), strokeWidth: 2)
                  : Text(
                      _sensexValue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              if (!_sensexLoading && _sensexChange.isNotEmpty)
                Text(
                  _sensexChange,
                  style: TextStyle(
                    color: _sensexUp ? Colors.green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_sensexUp ? Colors.green : Colors.red)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _sensexUp
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: _sensexUp ? Colors.green : Colors.red,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // ── Top 10 Carousel ──
  Widget _buildTop10Carousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '🔥 Top 10 Headlines',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1A1A),
          ),
          child: _isTop10Loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFCC0000)))
              : Stack(
                  children: [
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
                                builder: (_) => SwipeNewsScreen(
                                    articles: _top10),
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                article.urlToImage.isNotEmpty
                                    ? Image.network(
                                        article.urlToImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                Container(
                                          color: const Color(
                                              0xFF2A2A2A),
                                          child: const Icon(
                                              Icons.newspaper,
                                              color: Colors.grey,
                                              size: 60),
                                        ),
                                      )
                                    : Container(
                                        color:
                                            const Color(0xFF2A2A2A),
                                        child: const Icon(
                                            Icons.newspaper,
                                            color: Colors.grey,
                                            size: 60),
                                      ),
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
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
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
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                            duration:
                                const Duration(milliseconds: 300),
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
        ),
      ],
    );
  }

  // ── Cricket Section ──
  Widget _buildCricketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '🏏 Cricket Live Scores',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC0000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle,
                        color: Colors.white, size: 6),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _cricketLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFCC0000)))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  final isLive = match['status'] == 'Live';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLive
                            ? const Color(0xFFCC0000)
                                .withOpacity(0.5)
                            : Colors.grey.shade800,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                match['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? const Color(0xFFCC0000)
                                    : Colors.grey.shade800,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                match['status']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match['score']!,
                          style: TextStyle(
                            color: isLive
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ── Live Section ──
  Widget _buildLiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Icon(Icons.circle,
                        color: Colors.white, size: 8),
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
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
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
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCC0000)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCC0000),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.source,
                                  style: const TextStyle(
                                    color: Color(0xFFCC0000),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.grey, size: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ── Quick Access ──
  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '⚡ Quick Access',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.bookmark,
                  label: 'Bookmarks',
                  count: _bookmarkCount,
                  color: const Color(0xFFCC0000),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BookmarksScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.download_done,
                  label: 'Downloads',
                  count: _downloadCount,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DownloadsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}