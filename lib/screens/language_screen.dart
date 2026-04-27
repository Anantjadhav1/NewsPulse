import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interest_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    // Indian Languages
    {'code': 'en', 'name': 'English', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'mr', 'name': 'Marathi', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'gu', 'name': 'Gujarati', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'bn', 'name': 'Bengali', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'ta', 'name': 'Tamil', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'te', 'name': 'Telugu', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'kn', 'name': 'Kannada', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'ml', 'name': 'Malayalam', 'flag': '🇮🇳', 'group': 'Indian'},
    {'code': 'pa', 'name': 'Punjabi', 'flag': '🇮🇳', 'group': 'Indian'},
    // International Languages
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'group': 'International'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'group': 'International'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'group': 'International'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'group': 'International'},
    {'code': 'he', 'name': 'Hebrew', 'flag': '🇮🇱', 'group': 'International'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹', 'group': 'International'},
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱', 'group': 'International'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹', 'group': 'International'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺', 'group': 'International'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'group': 'International'},
  ];

  void _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage);
    await prefs.setBool('language_selected', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InterestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final indianLanguages =
        _languages.where((l) => l['group'] == 'Indian').toList();
    final intlLanguages =
        _languages.where((l) => l['group'] == 'International').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.language,
                    size: 70, color: Color(0xFFCC0000)),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Choose Your Language',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'You can change this later in Settings',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indian Languages section
                      _buildSectionHeader('🇮🇳 Indian Languages'),
                      const SizedBox(height: 10),
                      ...indianLanguages
                          .map((lang) => _buildLanguageTile(lang)),

                      const SizedBox(height: 20),

                      // International Languages section
                      _buildSectionHeader('🌍 International Languages'),
                      const SizedBox(height: 10),
                      ...intlLanguages
                          .map((lang) => _buildLanguageTile(lang)),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFCC0000).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFFCC0000).withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFCC0000),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(Map<String, String> lang) {
    final isSelected = _selectedLanguage == lang['code'];
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang['code']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A0000)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCC0000)
                : Colors.grey.shade800,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(lang['flag']!,
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Text(
              lang['name']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            if (lang['group'] == 'Indian') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.5)),
                ),
                child: const Text(
                  'Regional News',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFFCC0000)),
          ],
        ),
      ),
    );
  }
}