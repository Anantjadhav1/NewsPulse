import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'language_screen.dart';
import 'interest_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLanguage = 'en';
  String _currentEmail = '';
  List<String> _interests = [];

  final Map<String, String> _languageNames = {
    'en': '🇺🇸 English',
    'mr': '🇮🇳 Marathi',
    'hi': '🇮🇳 Hindi',
    'ar': '🇸🇦 Arabic',
    'de': '🇩🇪 German',
    'es': '🇪🇸 Spanish',
    'fr': '🇫🇷 French',
    'he': '🇮🇱 Hebrew',
    'it': '🇮🇹 Italian',
    'nl': '🇳🇱 Dutch',
    'no': '🇳🇴 Norwegian',
    'pt': '🇵🇹 Portuguese',
    'ru': '🇷🇺 Russian',
    'sv': '🇸🇪 Swedish',
    'zh': '🇨🇳 Chinese',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
      _currentEmail = prefs.getString('user_email') ?? 'Not logged in';
      _interests = prefs.getStringList('interests') ?? [];
    });
  }

  void _logout() async {
    await AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionTitle('👤 Account'),
            _buildCard(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFCC0000),
                    child: Text(
                      _currentEmail.isNotEmpty
                          ? _currentEmail[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: const Text(
                    'Logged in as',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  subtitle: Text(
                    _currentEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Language section
            _buildSectionTitle('🌍 Language'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.language,
                      color: Color(0xFFCC0000)),
                  title: const Text(
                    'Current Language',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _languageNames[_currentLanguage] ??
                        '🇺🇸 English',
                    style: const TextStyle(
                      color: Color(0xFFCC0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LanguageScreen()),
                    );
                    _loadSettings();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Interests section
            _buildSectionTitle('🎯 Your Interests'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.interests,
                      color: Color(0xFFCC0000)),
                  title: const Text(
                    'Manage Interests',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${_interests.length} interests selected',
                    style: const TextStyle(
                      color: Color(0xFFCC0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InterestScreen()),
                    );
                    _loadSettings();
                  },
                ),
                if (_interests.isNotEmpty) ...[
                  const Divider(color: Colors.grey, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests
                          .map(
                            (i) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCC0000)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFCC0000)
                                        .withOpacity(0.5)),
                              ),
                              child: Text(
                                i,
                                style: const TextStyle(
                                  color: Color(0xFFCC0000),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // About section
            _buildSectionTitle('ℹ️ About'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: Color(0xFFCC0000)),
                  title: const Text('App Version',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('1.0.0',
                      style: TextStyle(color: Colors.grey)),
                ),
                Divider(color: Colors.grey.shade800, height: 1),
                ListTile(
                  leading: const Icon(Icons.newspaper,
                      color: Color(0xFFCC0000)),
                  title: const Text('News Source',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('NewsAPI.org',
                      style: TextStyle(color: Colors.grey)),
                ),
                Divider(color: Colors.grey.shade800, height: 1),
                ListTile(
                  leading: const Icon(Icons.code,
                      color: Color(0xFFCC0000)),
                  title: const Text('Built with',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Flutter & Dart',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Logout
            _buildCard(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: Color(0xFFCC0000)),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFCC0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text('Logout',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: _logout,
                            child: const Text(
                              'Logout',
                              style:
                                  TextStyle(color: Color(0xFFCC0000)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                '📰 NewsApp • Made with Flutter',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(children: children),
    );
  }
}