import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'feed_screen.dart';
import 'swipe_news_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';
import 'search_screen.dart';
 
class NavScreen extends StatefulWidget {
  final List<Article> articles;
  const NavScreen({super.key, required this.articles});
 
  @override
  State<NavScreen> createState() => _NavScreenState();
}
 
class _NavScreenState extends State<NavScreen> {
  // FIX 1: Use PageController so bottom nav + swipe L/R are in sync
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  String _userEmail = '';
 
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
 
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
 
  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? '';
    });
  }
 
  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
 
  void _logout() async {
    await AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
 
  // FIX 7: No emojis in app bar titles
  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'NewsPulse';
      case 2:
        return 'Swipe News';
      default:
        return 'NewsPulse';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      // FIX 1: PageView enables natural horizontal swipe between screens
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          const DashboardScreen(),
          // FIX 2 & 4 & 6: FeedScreen with swipe button removed and location/language fixed
          const FeedScreen(),
          // FIX 8: SwipeNewsScreen with unlimited articles
          SwipeNewsScreen(articles: widget.articles),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(color: Colors.grey.shade800, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: const Color(0xFF0A0A0A),
          selectedItemColor: const Color(0xFFCC0000),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swipe_outlined),
              activeIcon: Icon(Icons.swipe),
              label: 'Swipe',
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Column(
          children: [
            // User Profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  bottom:
                      BorderSide(color: Colors.grey.shade800, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCC0000).withOpacity(0.5),
                        width: 3,
                      ),
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
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCC0000).withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'Premium Member',
                      style: TextStyle(
                        color: Color(0xFFCC0000),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 10),
 
            _buildDrawerNavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
            _buildDrawerNavItem(icon: Icons.newspaper, label: 'News Feed', index: 1),
            _buildDrawerNavItem(icon: Icons.swipe, label: 'Swipe News', index: 2),
 
            Divider(color: Colors.grey.shade800, height: 24),
 
            _buildDrawerAction(
              icon: Icons.playlist_play,
              label: 'My Playlists',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
                );
              },
            ),
            _buildDrawerAction(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
 
            const Spacer(),
 
            Divider(color: Colors.grey.shade800),
 
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
                            style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: _logout,
                        child: const Text('Logout',
                            style: TextStyle(color: Color(0xFFCC0000))),
                      ),
                    ],
                  ),
                );
              },
            ),
 
            const SizedBox(height: 16),
 
            // FIX 7: No emoji in version text
            const Text(
              'NewsPulse v1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
 
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
 
  Widget _buildDrawerNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _onTabTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: isSelected ? const Color(0xFFCC0000) : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
    );
  }
}