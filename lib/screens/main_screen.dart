import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'swipe_news_screen.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'interest_screen.dart';

class MainScreen extends StatefulWidget {
  final List<Article> articles;
  const MainScreen({super.key, required this.articles});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _userEmail = '';
  String _userPhone = '';
  List<String> _interests = [];
  int _selectedIndex = 0;
  late List<Article> _articles;

  final List<String> _sectionTitles = [
    'Swipe News',
    'All News',
    'Bookmarks',
    'Downloads',
  ];

  final List<IconData> _sectionIcons = [
    Icons.swipe,
    Icons.newspaper,
    Icons.bookmark,
    Icons.download_done,
  ];

  @override
  void initState() {
    super.initState();
    _articles = widget.articles;
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
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

  Widget _buildCurrentSection() {
    switch (_selectedIndex) {
      case 0:
        return SwipeNewsScreen(articles: _articles);
      case 1:
        return const HomeScreen();
      case 2:
        return const BookmarksScreen();
      case 3:
        return const DownloadsScreen();
      default:
        return SwipeNewsScreen(articles: _articles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Icon(
              _sectionIcons[_selectedIndex],
              color: const Color(0xFFCC0000),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              _sectionTitles[_selectedIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFCC0000)),
              onPressed: () async {
                final articles =
                    await ApiService().fetchTopHeadlines();
                setState(() => _articles = articles);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _buildCurrentSection(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Column(
          children: [
            // ── User Profile Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  bottom: BorderSide(
                      color: Colors.grey.shade800, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFCC0000)
                              .withOpacity(0.5),
                          width: 3),
                    ),
                    child: Center(
                      child: Text(
                        _userEmail.isNotEmpty
                            ? _userEmail[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Phone
                  if (_userPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone,
                            color: Colors.grey, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          _userPhone,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Interest tags
                  if (_interests.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: _interests
                          .take(4)
                          .map(
                            (i) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCC0000)
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCC0000)
                                      .withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                i,
                                style: const TextStyle(
                                  color: Color(0xFFCC0000),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Navigation Items ──
            _buildDrawerItem(
              icon: Icons.swipe,
              label: 'Swipe News',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.newspaper,
              label: 'All News',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.bookmark,
              label: 'Bookmarks',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.download_done,
              label: 'Downloads',
              index: 3,
            ),

            Divider(color: Colors.grey.shade800, height: 24),

            // ── Other Options ──
            _buildDrawerAction(
              icon: Icons.interests,
              label: 'Manage Interests',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InterestScreen()),
                ).then((_) => _loadUserData());
              },
            ),
            _buildDrawerAction(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const Spacer(),

            Divider(color: Colors.grey.shade800, height: 1),

            const SizedBox(height: 8),

            // ── Logout ──
            _buildDrawerAction(
              icon: Icons.logout,
              label: 'Logout',
              color: const Color(0xFFCC0000),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: _logout,
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Color(0xFFCC0000)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              '📰 NewsApp v1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFCC0000).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCC0000).withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFCC0000)
                  : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 15,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFCC0000),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}