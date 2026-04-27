import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/bookmark_service.dart';
import '../widgets/article_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Article> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() async {
    final list = await BookmarkService().getBookmarks();
    setState(() {
      _bookmarks = list;
      _isLoading = false;
    });
  }

  void _removeBookmark(int index) async {
    await BookmarkService().removeBookmark(index);
    setState(() => _bookmarks.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed!'),
        backgroundColor: Color(0xFFCC0000),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'My Bookmarks',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFCC0000)))
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.bookmark_border,
                            size: 60, color: Color(0xFFCC0000)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No bookmarks yet!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save articles to read them later',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(_bookmarks[index].url),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: const Color(0xFFCC0000),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) => _removeBookmark(index),
                      child: ArticleCard(article: _bookmarks[index]),
                    );
                  },
                ),
    );
  }
}
