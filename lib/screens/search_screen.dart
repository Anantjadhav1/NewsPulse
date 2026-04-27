import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../widgets/article_card.dart';
 
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
 
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
 
class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Article> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';
 
  // Trending topics for quick search
  final List<String> _trending = [
    'India', 'Cricket', 'Sensex', 'AI', 'Modi',
    'IPL', 'Bitcoin', 'Space', 'Climate', 'Elections',
  ];
 
  @override
  void initState() {
    super.initState();
    // Auto-focus search bar when screen opens
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
 
  void _search(String query) async {
    if (query.trim().isEmpty) return;
    if (query == _lastQuery && _results.isNotEmpty) return;
 
    _lastQuery = query;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    _focusNode.unfocus();
 
    try {
      final results = await ApiService().searchNews(query);
      if (!mounted) return;
      setState(() {
        _results = results;
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search news...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                        _lastQuery = '';
                      });
                      _focusNode.requestFocus();
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_searchController.text),
            child: const Text(
              'Search',
              style: TextStyle(
                color: Color(0xFFCC0000),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Divider(color: Colors.grey.shade800, height: 1),
 
          // Body content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFCC0000)))
                : !_hasSearched
                    ? _buildTrendingTopics()
                    : _results.isEmpty
                        ? _buildNoResults()
                        : _buildResults(),
          ),
        ],
      ),
    );
  }
 
  Widget _buildTrendingTopics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Topics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trending.map((topic) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = topic;
                  _search(topic);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFCC0000).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up,
                          color: Color(0xFFCC0000), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Text(
            'Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildCategoryChip('Technology', Icons.computer),
              _buildCategoryChip('Sports', Icons.sports_cricket),
              _buildCategoryChip('Business', Icons.business),
              _buildCategoryChip('Health', Icons.health_and_safety),
              _buildCategoryChip('Science', Icons.science),
              _buildCategoryChip('Politics', Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildCategoryChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _search(label);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFCC0000), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: 60),
          const SizedBox(height: 16),
          Text(
            'No results for "$_lastQuery"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
 
  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '${_results.length} results for "$_lastQuery"',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) =>
                ArticleCard(article: _results[index]),
          ),
        ),
      ],
    );
  }
}