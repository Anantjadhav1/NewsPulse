import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_screen.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  final List<Map<String, dynamic>> _interests = [
    {'label': 'Politics', 'icon': '🏛️', 'query': 'politics'},
    {'label': 'Science & Space', 'icon': '🚀', 'query': 'science'},
    {'label': 'Gaming', 'icon': '🎮', 'query': 'gaming'},
    {'label': 'Fashion & Lifestyle', 'icon': '👗', 'query': 'fashion'},
    {'label': 'Cricket & Sports', 'icon': '🏏', 'query': 'cricket'},
    {'label': 'Stock Market', 'icon': '📈', 'query': 'stocks'},
    {'label': 'Movies & Entertainment', 'icon': '🎬', 'query': 'entertainment'},
    {'label': 'Food & Travel', 'icon': '✈️', 'query': 'travel'},
    {'label': 'Technology', 'icon': '💻', 'query': 'technology'},
    {'label': 'Health & Fitness', 'icon': '💪', 'query': 'health'},
    {'label': 'Business', 'icon': '💼', 'query': 'business'},
    {'label': 'Environment', 'icon': '🌱', 'query': 'environment'},
    {'label': 'Education', 'icon': '📚', 'query': 'education'},
    {'label': 'Art & Culture', 'icon': '🎨', 'query': 'art'},
    {'label': 'Automobiles', 'icon': '🚗', 'query': 'automobiles'},
    {'label': 'Crypto & Web3', 'icon': '🪙', 'query': 'crypto'},
    {'label': 'World News', 'icon': '🌍', 'query': 'world'},
    {'label': 'Weather', 'icon': '🌤️', 'query': 'weather'},
    {'label': 'Defense & Military', 'icon': '⚔️', 'query': 'military'},
    {'label': 'Social Media', 'icon': '📱', 'query': 'social media'},
  ];

  final List<String> _selectedInterests = [];

  void _saveAndContinue() async {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('interests', _selectedInterests);
    await prefs.setBool('interests_selected', true);
    Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const LocationScreen()),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'What are you\ninterested in?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select at least 3 to personalize your feed',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _interests.length,
                  itemBuilder: (context, index) {
                    final interest = _interests[index];
                    final isSelected =
                        _selectedInterests.contains(interest['query']);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest['query']);
                          } else {
                            _selectedInterests.add(interest['query']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFCC0000)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF0000)
                                : Colors.grey.shade800,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(interest['icon'],
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                interest['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${_selectedInterests.length} selected',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
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
                        'Continue →',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}