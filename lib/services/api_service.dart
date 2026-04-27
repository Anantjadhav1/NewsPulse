import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/article_model.dart';
import 'rss_service.dart';

class ApiService {
  static String get _apiKey => dotenv.env['NEWS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://newsapi.org/v2';

  // NewsAPI supported languages
  static const List<String> _newsApiLanguages = [
    'ar', 'de', 'en', 'es', 'fr', 'he', 'it', 'nl', 'no', 'pt', 'ru', 'sv', 'zh'
  ];

  // Get saved language from prefs
  Future<String> _getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'en';
  }

  // Check if language needs RSS (Indian languages)
  bool _needsRss(String lang) {
    return RssService.isIndianLanguage(lang);
  }

  // ── Fetch by category ──
  Future<List<Article>> fetchByCategory(String category,
      {String? language}) async {
    final lang = language ?? await _getSavedLanguage();

    // Indian language → use Google RSS
    if (_needsRss(lang)) {
      return await RssService().fetchIndianNews(lang, topic: category);
    }

    // English/International → use NewsAPI
    final safeLang =
        _newsApiLanguages.contains(lang) ? lang : 'en';
    final url = Uri.parse(
        '$_baseUrl/top-headlines?category=$category&language=$safeLang&pageSize=30&apiKey=$_apiKey');
    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['articles'] as List)
            .where((a) =>
                a['title'] != null &&
                a['title'] != '[Removed]' &&
                a['description'] != null &&
                a['description'] != '[Removed]')
            .map((a) => Article.fromJson(a))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      print('fetchByCategory error: $e');
    }
    return [];
  }

  // ── Fetch top headlines ──
  Future<List<Article>> fetchTopHeadlines({int page = 1}) async {
    final lang = await _getSavedLanguage();

    // Indian language → use Google RSS
    if (_needsRss(lang)) {
      return await RssService().fetchIndianNews(lang);
    }

    // English/International → use NewsAPI
    final safeLang =
        _newsApiLanguages.contains(lang) ? lang : 'en';
    final url = Uri.parse(
        '$_baseUrl/top-headlines?language=$safeLang&pageSize=20&page=$page&apiKey=$_apiKey');
    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['articles'] as List)
            .where((a) =>
                a['title'] != null &&
                a['title'] != '[Removed]' &&
                a['description'] != null &&
                a['description'] != '[Removed]')
            .map((a) => Article.fromJson(a))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      print('fetchTopHeadlines error: $e');
    }
    return [];
  }

  // ── Fetch top 10 ──
  Future<List<Article>> fetchTop10Headlines() async {
    final articles = await fetchTopHeadlines();
    return articles.take(10).toList();
  }

  // ── Search news ──
  Future<List<Article>> searchNews(String query,
      {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final lang = await _getSavedLanguage();

    // Indian language → use Google RSS search
    if (_needsRss(lang)) {
      return await RssService().fetchIndianNews(lang, topic: query);
    }

    // English/International → use NewsAPI
    final url = Uri.parse(
        '$_baseUrl/everything?q=${Uri.encodeComponent(query)}&sortBy=publishedAt&pageSize=20&page=$page&apiKey=$_apiKey');
    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['articles'] as List)
            .where((a) =>
                a['title'] != null &&
                a['title'] != '[Removed]' &&
                a['description'] != null &&
                a['description'] != '[Removed]')
            .map((a) => Article.fromJson(a))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      print('searchNews error: $e');
    }
    return [];
  }
}