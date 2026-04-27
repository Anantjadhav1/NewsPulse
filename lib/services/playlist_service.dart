import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

class PlaylistService {
  final String _key = 'playlists';

  // Get all playlists
  Future<Map<String, List<Article>>> getAllPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return {};
    final Map<String, dynamic> decoded = json.decode(saved);
    return decoded.map((key, value) {
      final List<Article> articles = (value as List)
          .map((e) => Article.fromJson(e))
          .toList();
      return MapEntry(key, articles);
    });
  }

  // Create new playlist
  Future<void> createPlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    if (!playlists.containsKey(name)) {
      playlists[name] = [];
      await prefs.setString(
        _key,
        json.encode(playlists.map((key, value) =>
            MapEntry(key, value.map((a) => a.toJson()).toList()))),
      );
    }
  }

  // Add article to playlist
  Future<void> addToPlaylist(
      String playlistName, Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    if (!playlists.containsKey(playlistName)) {
      playlists[playlistName] = [];
    }
    // Check if already exists
    final exists = playlists[playlistName]!
        .any((a) => a.url == article.url);
    if (!exists) {
      playlists[playlistName]!.add(article);
      await prefs.setString(
        _key,
        json.encode(playlists.map((key, value) =>
            MapEntry(key, value.map((a) => a.toJson()).toList()))),
      );
    }
  }

  // Remove article from playlist
  Future<void> removeFromPlaylist(
      String playlistName, String articleUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    if (playlists.containsKey(playlistName)) {
      playlists[playlistName]!
          .removeWhere((a) => a.url == articleUrl);
      await prefs.setString(
        _key,
        json.encode(playlists.map((key, value) =>
            MapEntry(key, value.map((a) => a.toJson()).toList()))),
      );
    }
  }

  // Delete entire playlist
  Future<void> deletePlaylist(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    playlists.remove(playlistName);
    await prefs.setString(
      _key,
      json.encode(playlists.map((key, value) =>
          MapEntry(key, value.map((a) => a.toJson()).toList()))),
    );
  }

  // Get articles in a playlist
  Future<List<Article>> getPlaylistArticles(
      String playlistName) async {
    final playlists = await getAllPlaylists();
    return playlists[playlistName] ?? [];
  }

  // Get playlist names
  Future<List<String>> getPlaylistNames() async {
    final playlists = await getAllPlaylists();
    return playlists.keys.toList();
  }

  // Check if article is in any playlist
  Future<List<String>> getArticlePlaylists(
      String articleUrl) async {
    final playlists = await getAllPlaylists();
    List<String> result = [];
    playlists.forEach((name, articles) {
      if (articles.any((a) => a.url == articleUrl)) {
        result.add(name);
      }
    });
    return result;
  }
}