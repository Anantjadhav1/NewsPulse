import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class RssService {
  static const Map<String, String> _languageFeeds = {
    'hi': 'https://news.google.com/rss?hl=hi&gl=IN&ceid=IN:hi',
    'mr': 'https://news.google.com/rss?hl=mr&gl=IN&ceid=IN:mr',
    'gu': 'https://news.google.com/rss?hl=gu&gl=IN&ceid=IN:gu',
    'bn': 'https://news.google.com/rss?hl=bn&gl=IN&ceid=IN:bn',
    'ta': 'https://news.google.com/rss?hl=ta&gl=IN&ceid=IN:ta',
    'te': 'https://news.google.com/rss?hl=te&gl=IN&ceid=IN:te',
    'kn': 'https://news.google.com/rss?hl=kn&gl=IN&ceid=IN:kn',
    'ml': 'https://news.google.com/rss?hl=ml&gl=IN&ceid=IN:ml',
    'pa': 'https://news.google.com/rss?hl=pa&gl=IN&ceid=IN:pa',
  };

  static bool isIndianLanguage(String langCode) {
    return _languageFeeds.containsKey(langCode);
  }

  Future<List<Article>> fetchIndianNews(String langCode,
      {String? topic}) async {
    try {
      String feedUrl = _languageFeeds[langCode] ??
          'https://news.google.com/rss?hl=hi&gl=IN&ceid=IN:hi';

      if (topic != null && topic.isNotEmpty) {
        feedUrl =
            'https://news.google.com/rss/search?q=${Uri.encodeComponent(topic)}&hl=$langCode&gl=IN&ceid=IN:$langCode';
      }

      final response = await http
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseRss(response.body, langCode);
      }
    } catch (e) {
      print('RSS fetch error: $e');
    }
    return [];
  }

  List<Article> _parseRss(String xmlString, String langCode) {
    final List<Article> articles = [];
    try {
      final itemRegex =
          RegExp(r'<item>(.*?)</item>', dotAll: true);
      final items = itemRegex.allMatches(xmlString);

      for (final item in items) {
        final itemContent = item.group(1) ?? '';

        // Extract title
        final titleMatch =
            RegExp(r'<title>(.*?)</title>', dotAll: true)
                .firstMatch(itemContent);
        String title = titleMatch?.group(1) ?? '';
        title = _cleanText(title);

        // Extract link
        final linkMatch =
            RegExp(r'<link>(.*?)</link>', dotAll: true)
                .firstMatch(itemContent);
        final link = linkMatch?.group(1)?.trim() ?? '';

        // Extract description — properly clean HTML
        final descMatch =
            RegExp(r'<description>(.*?)</description>', dotAll: true)
                .firstMatch(itemContent);
        String description = descMatch?.group(1) ?? '';
        // Clean HTML properly
        description = _cleanDescription(description);
        // If description is still empty or too short, use title
        if (description.length < 20) description = title;

        // Extract pub date
        final dateMatch =
            RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true)
                .firstMatch(itemContent);
        final pubDate = dateMatch?.group(1)?.trim() ?? '';

        // Extract source
        final sourceMatch =
            RegExp(r'<source[^>]*>(.*?)</source>', dotAll: true)
                .firstMatch(itemContent);
        String source = sourceMatch?.group(1) ?? 'Google News';
        source = _cleanText(source);

        if (title.isNotEmpty && link.isNotEmpty) {
          articles.add(Article(
            title: title,
            description: description,
            url: link,
            urlToImage: '',
            publishedAt: pubDate,
            source: source,
          ));
        }

        if (articles.length >= 20) break;
      }
    } catch (e) {
      print('RSS parse error: $e');
    }
    return articles;
  }

  // Clean description — remove ALL HTML tags and links
  String _cleanDescription(String text) {
    // Remove CDATA wrapper
    text = text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '');

    // Remove all <a href...>...</a> tags completely
    text = text.replaceAll(
        RegExp(r'<a\s[^>]*>.*?</a>', dotAll: true), '');

    // Remove all other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Remove URLs that might be left over
    text = text.replaceAll(
        RegExp(
            r'https?://[^\s]+',
            caseSensitive: false),
        '');

    // Decode HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '...');

    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  // Clean simple text fields
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}