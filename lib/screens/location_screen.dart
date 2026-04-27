import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../models/article_model.dart';
import 'nav_screen.dart';
 
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
 
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}
 
class _LocationScreenState extends State<LocationScreen> {
  final _cityController = TextEditingController();
  bool _isLoadingGPS = false;
  bool _isSaving = false;
  String _detectedCity = '';
 
  final List<String> _popularCities = [
    'Mumbai', 'Pune', 'Delhi', 'Bangalore',
    'Hyderabad', 'Chennai', 'Kolkata', 'Ahmedabad',
    'Jaipur', 'Surat', 'Nagpur', 'Nashik',
  ];
 
  void _useGPS() async {
    setState(() => _isLoadingGPS = true);
    try {
      Position? position =
          await LocationService().getCurrentPosition();
      if (position != null) {
        await LocationService().saveLocationFromGPS(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _detectedCity =
              '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
          _cityController.text = 'Current Location';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS location detected!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please enter manually.'),
            backgroundColor: Color(0xFFCC0000),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFCC0000),
        ),
      );
    }
    if (mounted) setState(() => _isLoadingGPS = false);
  }
 
  void _saveAndContinue() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your city or use GPS'),
          backgroundColor: Color(0xFFCC0000),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    await LocationService().saveCity(city);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_set', true);
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    _goToApp();
  }
 
  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_set', true);
    await prefs.setBool('onboarding_complete', true);
    await LocationService().saveCity('India');
    if (!mounted) return;
    _goToApp();
  }
 
  void _goToApp() async {
    try {
      final articles = await ApiService().fetchTopHeadlines();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NavScreen(articles: articles)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NavScreen(articles: const [])),
        (route) => false,
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
 
              const Center(
                child: Icon(Icons.location_on,
                    size: 80, color: Color(0xFFCC0000)),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Where are you?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Get news from your city first!',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
 
              const SizedBox(height: 40),
 
              // GPS button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingGPS ? null : _useGPS,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFFCC0000), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoadingGPS
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFCC0000),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.gps_fixed,
                          color: Color(0xFFCC0000)),
                  label: Text(
                    _isLoadingGPS
                        ? 'Detecting location...'
                        : 'Use My GPS Location',
                    style: const TextStyle(
                      color: Color(0xFFCC0000),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
 
              const SizedBox(height: 20),
 
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade800)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade800)),
                ],
              ),
 
              const SizedBox(height: 20),
 
              const Text(
                'Enter Your City',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Pune, Mumbai, Delhi...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.location_city,
                      color: Color(0xFFCC0000)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFCC0000), width: 2),
                  ),
                ),
              ),
 
              const SizedBox(height: 20),
 
              const Text(
                'Popular Cities',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularCities.map((city) {
                  final isSelected = _cityController.text == city;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _cityController.text = city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFCC0000)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFCC0000)
                              : Colors.grey.shade800,
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
 
              const SizedBox(height: 30),
 
              SizedBox(
                width: double.infinity,
                height: 54,
                child: _isSaving
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFCC0000)))
                    : ElevatedButton(
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
 
              const SizedBox(height: 12),
 
              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
 
              const SizedBox(height: 20),
              _buildStepsIndicator(),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildStepsIndicator() {
    return Column(
      children: [
        const Text(
          'Setup Steps',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStep('1', 'Register', true),
            _buildStepLine(),
            _buildStep('2', 'Language', true),
            _buildStepLine(),
            _buildStep('3', 'Interests', true),
            _buildStepLine(),
            _buildStep('4', 'Location', true),
          ],
        ),
      ],
    );
  }
 
  Widget _buildStep(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFCC0000)
                : const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? const Color(0xFFCC0000)
                  : Colors.grey.shade700,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFCC0000) : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
 
  Widget _buildStepLine() {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: Colors.grey.shade800,
    );
  }
}