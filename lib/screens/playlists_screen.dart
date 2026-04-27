import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/playlist_service.dart';
import '../widgets/article_card.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  Map<String, List<Article>> _playlists = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() async {
    final playlists = await PlaylistService().getAllPlaylists();
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  void _createPlaylist() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Morning Read, Tech News...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFCC0000), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await PlaylistService().createPlaylist(name);
                Navigator.pop(context);
                _loadPlaylists();
              }
            },
            child: const Text('Create',
                style: TextStyle(
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Playlist',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await PlaylistService().deletePlaylist(name);
              Navigator.pop(context);
              _loadPlaylists();
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text(
          '📋 My Playlists',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle,
                color: Color(0xFFCC0000), size: 28),
            onPressed: _createPlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFCC0000)))
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade800),
                        ),
                        child: const Icon(
                          Icons.playlist_add,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Playlists Yet!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create playlists to organize\nyour favorite news',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createPlaylist,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFCC0000),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.add,
                            color: Colors.white),
                        label: const Text(
                          'Create First Playlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final name =
                        _playlists.keys.elementAt(index);
                    final articles = _playlists[name]!;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(
                            playlistName: name,
                            articles: articles,
                          ),
                        ),
                      ).then((_) => _loadPlaylists()),
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.grey.shade800),
                        ),
                        child: Column(
                          children: [
                            // Playlist header
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(
                                            10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                              0xFFCC0000)
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                    ),
                                    child: const Icon(
                                      Icons.playlist_play,
                                      color: Color(0xFFCC0000),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${articles.length} articles',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () =>
                                        _deletePlaylist(name),
                                  ),
                                  const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: 14),
                                ],
                              ),
                            ),
                            // Preview of articles
                            if (articles.isNotEmpty) ...[
                              Divider(
                                  color: Colors.grey.shade800,
                                  height: 1),
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection:
                                      Axis.horizontal,
                                  padding:
                                      const EdgeInsets.all(8),
                                  itemCount: articles.length > 5
                                      ? 5
                                      : articles.length,
                                  itemBuilder:
                                      (context, artIndex) {
                                    final article =
                                        articles[artIndex];
                                    return Container(
                                      width: 44,
                                      height: 44,
                                      margin:
                                          const EdgeInsets.only(
                                              right: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF2A2A2A),
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                        image: article.urlToImage
                                                .isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    article
                                                        .urlToImage),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: article.urlToImage
                                              .isEmpty
                                          ? const Icon(
                                              Icons.newspaper,
                                              color: Colors.grey,
                                              size: 20)
                                          : null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Playlist Detail Screen ──
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  final List<Article> articles;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.articles,
  });

  @override
  State<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState
    extends State<PlaylistDetailScreen> {
  late List<Article> _articles;

  @override
  void initState() {
    super.initState();
    _articles = widget.articles;
  }

  void _removeArticle(Article article) async {
    await PlaylistService().removeFromPlaylist(
        widget.playlistName, article.url);
    setState(
        () => _articles.removeWhere((a) => a.url == article.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from playlist'),
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
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playlistName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_articles.length} articles',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _articles.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No articles in this playlist',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add articles from the news feed',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                return Dismissible(
                  key: Key(article.url),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        Text('Remove',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _removeArticle(article),
                  child: ArticleCard(article: article),
                );
              },
            ),
    );
  }
}