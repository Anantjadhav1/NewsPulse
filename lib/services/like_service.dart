import 'package:shared_preferences/shared_preferences.dart';

class LikeService {
  final String _likedKey = 'liked_articles';
  final String _interestScoreKey = 'interest_scores';

  // Like or unlike an article
  Future<bool> toggleLike(String articleUrl) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> liked = prefs.getStringList(_likedKey) ?? [];
    if (liked.contains(articleUrl)) {
      liked.remove(articleUrl);
      await prefs.setStringList(_likedKey, liked);
      return false; // unliked
    } else {
      liked.add(articleUrl);
      await prefs.setStringList(_likedKey, liked);
      return true; // liked
    }
  }

  // Check if article is liked
  Future<bool> isLiked(String articleUrl) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> liked = prefs.getStringList(_likedKey) ?? [];
    return liked.contains(articleUrl);
  }

  // Add interest score when user likes article
  Future<void> addInterestScore(String category) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> scores = {};
    final saved = prefs.getStringList(_interestScoreKey) ?? [];
    for (var item in saved) {
      final parts = item.split(':');
      if (parts.length == 2) {
        scores[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    scores[category] = (scores[category] ?? 0) + 1;
    final updated =
        scores.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_interestScoreKey, updated);
  }

  // Get top interests based on likes
  Future<List<String>> getTopInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_interestScoreKey) ?? [];
    Map<String, int> scores = {};
    for (var item in saved) {
      final parts = item.split(':');
      if (parts.length == 2) {
        scores[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  // Get total likes count
  Future<int> getTotalLikes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_likedKey) ?? []).length;
  }
}