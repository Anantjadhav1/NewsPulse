import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../widgets/article_card.dart';
import 'swipe_news_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Article> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'For You';
  String _userCity = '';
  List<String> _userInterests = [];

  final List<Map<String, String>> _categories = [
    {'label': 'For You', 'query': 'general'},
    {'label': '📍 Local', 'query': 'local'},
    {'label': '🔥 Trending', 'query': 'general'},
    {'label': '💻 Tech', 'query': 'technology'},
    {'label': '🏏 Sports', 'query': 'sports'},
    {'label': '💼 Business', 'query': 'business'},
    {'label': '🎬 Entertainment', 'query': 'entertainment'},
    {'label': '💪 Health', 'query': 'health'},
    {'label': '🚀 Science', 'query': 'science'},
    {'label': '🌍 World', 'query': 'world'},
    {'label': '🏛️ Politics', 'query': 'politics'},
    {'label': '📈 Finance', 'query': 'finance'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userCity = prefs.getString('user_city') ?? 'India';
      _userInterests = prefs.getStringList('interests') ?? [];
    });
    _loadNews('general');
  }

  void _loadNews(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Article> articles;
      if (query == 'local') {
        articles = await ApiService().searchNews(_userCity);
      } else if (query == 'world') {
        articles = await ApiService().searchNews('world news');
      } else if (query == 'politics') {
        articles = await ApiService().searchNews('politics');
      } else if (query == 'finance') {
        articles = await ApiService().searchNews('finance economy');
      } else {
        articles = await ApiService().fetchByCategory(query);
      }
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    '📰 NewsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  // Location indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFCC0000)
                              .withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFFCC0000), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _userCity,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected =
                      _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () {
                      setState(
                          () => _selectedCategory = cat['label']!);
                      _loadNews(cat['query']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                          color: isSelected
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Swipe mode button
            GestureDetector(
              onTap: () {
                if (_articles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SwipeNewsScreen(articles: _articles),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFCC0000),
                      Color(0xFF880000)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swipe_vertical,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Swipe Mode — Read like Reels!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // News list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFCC0000)))
                  : _articles.isEmpty
                      ? const Center(
                          child: Text(
                            'No articles found!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFCC0000),
                          onRefresh: () async =>
                              _loadNews(_selectedCategory),
                          child: ListView.builder(
                            itemCount: _articles.length,
                            itemBuilder: (context, index) =>
                                ArticleCard(
                                    article: _articles[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}