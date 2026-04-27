import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

class DownloadService {
  final String _key = 'downloaded_articles';

  // Download article for offline
  Future<void> downloadArticle(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];

    // Check if already downloaded
    bool alreadyExists = saved.any((e) {
      final decoded = json.decode(e);
      return decoded['url'] == article.url;
    });

    if (!alreadyExists) {
      saved.add(json.encode(article.toJson()));
      await prefs.setStringList(_key, saved);
    }
  }

  // Get all downloaded articles
  Future<List<Article>> getDownloadedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    return saved.map((e) => Article.fromJson(json.decode(e))).toList();
  }

  // Remove downloaded article
  Future<void> removeDownload(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    saved.removeWhere((e) {
      final decoded = json.decode(e);
      return decoded['url'] == url;
    });
    await prefs.setStringList(_key, saved);
  }

  // Check if article is downloaded
  Future<bool> isDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(_key) ?? [];
    return saved.any((e) {
      final decoded = json.decode(e);
      return decoded['url'] == url;
    });
  }

  // Get total downloaded count
  Future<int> getDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).length;
  }
}