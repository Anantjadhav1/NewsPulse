import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  final Map<String, String> _cache = {};

  // Clean HTML before sending to Gemini
  String _cleanHtml(String text) {
    // Remove CDATA
    text = text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '');
    // Remove all HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Remove URLs
    text = text.replaceAll(
        RegExp(r'https?://[^\s]+', caseSensitive: false), '');
    // Decode HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Clean extra spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  Future<String> summarizeArticle({
    required String title,
    required String description,
    required String source,
  }) async {
    // Clean HTML from title and description first
    final cleanTitle = _cleanHtml(title);
    final cleanDesc = _cleanHtml(description);

    // If after cleaning nothing is left, return cleaned title
    if (cleanDesc.isEmpty && cleanTitle.isEmpty) return source;
    if (cleanDesc.isEmpty) return cleanTitle;

    // Cache check
    final cacheKey = cleanTitle.substring(
        0, cleanTitle.length.clamp(0, 50));
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Summarize this news article in 2-3 simple sentences.
Write in the same language as the article.
Do not add any intro, just write the summary directly.

Title: $cleanTitle
Content: $cleanDesc

Summary:''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final summary = response.text?.trim() ?? cleanDesc;

      _cache[cacheKey] = summary;
      return summary;
    } catch (e) {
      print('Gemini error: $e');
      // Return clean description as fallback
      return cleanDesc.isNotEmpty ? cleanDesc : cleanTitle;
    }
  }
}