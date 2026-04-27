import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

class BookmarkService {
  final String _key = 'bookmarks';

  // Save article to bookmarks
  Future<void> saveBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    saved.add(json.encode(article.toJson()));
    await prefs.setStringList(_key, saved);
  }

  // Get all bookmarked articles
  Future<List<Article>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    return saved.map((e) => Article.fromJson(json.decode(e))).toList();
  }

  // Remove a bookmark
  Future<void> removeBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    saved.removeAt(index);
    await prefs.setStringList(_key, saved);
  }
}