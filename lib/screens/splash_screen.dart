import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/article_model.dart';
import 'nav_screen.dart';
import 'login_screen.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }
 
  void _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
 
    final bool loggedIn = await AuthService().isLoggedIn();
 
    if (loggedIn) {
      try {
        final List<Article> articles =
            await ApiService().fetchTopHeadlines();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NavScreen(articles: articles),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.newspaper,
                  size: 70, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'NewsPulse',
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stay informed, Stay ahead',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFFCC0000),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading latest news...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}